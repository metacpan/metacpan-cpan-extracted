#!/usr/local/bin/perl
#
# Copyright (c) 1997-1999 Kevin Johnson <kjj@pobox.com>.
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: xAP.pm,v 1.2 1999/10/03 15:00:19 kjj Exp $

require 5.005;

package Net::xAP;

use strict;

=head1 NAME

Net::xAP - A base class for protocols such as IMAP, ACAP, IMSP, and ICAP.

=head1 SYNOPSIS

C<use Net::xAP;>

B<WARNING: This code is in alpha release.  Expect the interface to
change from release to release.>

=head1 DESCRIPTION

This base class implements the substrate common across the IMAP, ACAP,
IMSP, and ICAP protocols.  It provides the interface to the network
calls and implements a small amount of glue to assist in implementing
interfaces to this protocol family.

=cut

use IO::Socket;
use Carp;

use vars qw($VERSION @ISA);

$VERSION = '0.02';

use constant ATOM => 0;
use constant ASTRING => 1;
use constant PARENS => 2;
use constant STRING => 3;
use constant SASLRESP => 4;
use constant QSTRING => 5;

=head1 END-PROGRAMMER METHODS

The following methods are potentially useful for end-programmers.

=head2 last_command_time

Return what time the most recent command was sent to the server.  The
return value is a C<time> integer.

=cut

sub last_command_time { return $_[0]->{LastCmdTime} }

=head2 connection

Returns the connection object being used by the object.

=cut

sub connection { return $_[0]->{Connection} }

=head1 PROTOCOL-DEVELOPER METHODS

The following methods are probably only useful to protocol developers.

=head2 new $host, $peerport [, %options]

Create a new instance of Net::xAP, connects to C<$host>, and returns a
reference to the object.

The C<$host> parameter is the name of the host to contact.  If
C<$host> starts with a C</> character, the parameter is assumed to
contain the name of a program and the given program is spawned as a
child process.  This is useful for driving programs that can be
operated interactively from the command-line, such as UW-imapd.

The C<$peerport> parameter specifies the TCP port used for the network
connection. The parameter should be in the syntax understood by
C<IO::Socket::INET-E<gt>new>.  This parameter is ignored if a child
process is spawned.

The C<%options> parameter specifies any options to use.  The following
list enumerates the options, and their default values, currently
understood by C<Net::xAP>:

=over 4

=item C<Synchronous =E<gt> 1>

Setting this option causes C<Net::xAP> to issue a C<response> method
immediately after sending the command to the server.  Currently, this
option should always be left on.  Non-synchronous command/response
processing has not been tested.

One down-side to Synchronous mode is that commands cannot be sent to
the server from within a callback.  Instead, the results should be
saved, and the commands should be sent after the current command has
completed.

=item C<NonSyncLits =E<gt> 0>

Setting this option causes C<Net::xAP> to use non-synchronizing
literals.  This should only be enabled if the protocol and server this
feature.

=item C<Debug =E<gt> 0>

Setting this option causes debug output to be written to C<stderr>.
See the C<debug_print> method for a description of the output format.

=item C<InternetDraft =E<gt> 0>

Setting this option adds support for various extensions that are still
in Internet Draft.  This option is only intended to be used by
protocol developers.  Most bug reports related to this feature will be
ignored.

=back

All options are also passed to the internal call to
C<IO::Socket::INET-E<gt>new>, unless a child IMAP process is spawned.

=cut

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $host = shift;
  my $peerport = shift;
  my %options = @_;

  my $self = bless {}, $class;

  $self->{Options}  = {%options};

  # some default option settings
  $self->{Options}{Synchronous} ||= 1;
  $self->{Options}{Debug} ||= 0;
  $self->{Options}{NonSyncLits} ||= 0;

  if (substr($host, 0, 1) eq '/') {
    my ($child, $parent) = IO::Socket->socketpair(AF_UNIX,
						  SOCK_STREAM, PF_UNSPEC)
      or croak "socketpair: $!";
    $child->autoflush(1);
    $parent->autoflush(1);
    my $pid;
    if ($pid = fork) {
      $self->{Connection} = $child;
      $parent->close;
    } else {
      croak "can't fork: $!\n" unless defined($pid);
      $child->close;
      open(STDIN,  "<&" . $parent->fileno)
	or croak "can't dup parent to stdin: $!\n";
      open(STDOUT, ">&" . $parent->fileno)
	or croak "can't dup parent to stdout: $!\n";
      $^W = 0;			# squelch warning emitted by exec()
      exec($host) or croak "can't exec $host: $!\n";
    }
  } else {
    $self->{Connection} = IO::Socket::INET->new(PeerAddr => $host,
						PeerPort => $peerport,
						Proto => 'tcp',
						%options) or return undef;
    $self->{Connection}->autoflush(1);
  }

  $self->{Pending} = ();
  $self->{Sequence} = 0;

  return $self;
}

=head2 command $callback, $command [, @args]

The C<command> is used to send commands to the server.

The C<$callback> parameter should be a reference to a subroutine. It
will be called when a response is received from the server.

C<@args> is a list of C<$type>-C<$value> pairs.  The C<$type>
indicates what type of data type to use for C<$value>.  This is used
to control the encoding necessary to pass the command arguments to the
server.

The following C<$type>s are understood:

=over 4

=item C<ATOM>

The data will sent raw to the server.

=item C<ASTRING>

The data will be sent to the server as an atom, a quoted string, or a
literal depending on the content of C<$value>.

=item C<PARENS>

The data in C<$value> will be interpreted as an array reference and be
sent inside a pair of parentheses.

=item C<STRING>

The data will be sent to the server as either a quoted string or
literal depending on the content of C<$value>.

=item C<QSTRING>

The data will be sent to the server as a quoted string.

=back

If the C<Synchronous> option is set this method will return a response
object, otherwise it will return the sequence number associated with
the command just sent to the server.

=cut

sub command {
  my $self = shift;
  my $cmd_callback = shift;
  my $cmd = shift;

  unless ($#_ % 2) {
    carp("odd number of args given to Net::xAP command method");
    return undef;
  }
  unless (defined($self->{Connection})) {
    carp("no connection open in $self");
    return undef;
  }

  my $resp;

  $self->{Sequence}++;

  $self->{Pending}{$self->{Sequence}} = $cmd_callback;

  my @list = ($self->{Sequence}, $cmd);
  while (my ($type, $value) = splice @_, 0, 2) {
    if ($type == ATOM) {	# maybe we should check for non-ATOM chars
      push @list, $value;
    } elsif ($type == PARENS) {
      push @list, '(' . join(' ', @{$value}) . ')';
    } elsif ($type == QSTRING) {
      $value =~ s/([\\\"])/\\$1/g;
      push @list, "\"$value\"";
    } elsif (($type == ASTRING) || ($type == STRING)) {
      my $astring
	= ($type == ASTRING)
	  ? $self->_as_astring($value)
	    : $self->_as_string($value);
      if (ref($astring) eq 'ARRAY') {
	if ($self->{Options}{NonSyncLits}) {
	  push @list, "{$astring->[0]+}\r\n$astring->[1]";
	} else {
	  push @list, "{$astring->[0]}";
	  $self->_send_string(join(' ', @list))->_send_eol;
	  my $list;
	  my $tag;
	  # loop until we get a continuation request or a
	  # command-completion response
	  while (1) {
	    my $str = $self->getline;
	    $tag = substr($str, 0, index($str, ' '));
	    last if ($tag eq '+');
	    last if (defined($self->_process_response($str)));
	  }
	  @list = ($astring->[1]) if $tag eq '+'
	}
      } else {
	push @list, $astring;
      }
    } elsif ($type == SASLRESP) {
      $self->_send_string(join(' ', @list))->_send_eol;
      my $list;
      my $tag;
      my $func = $value;
      my $i = 0;
    SASL: while (1) {
	my $str;
	while (1) {
	  $str = $self->getline;
	  ($tag) = split(/\s/, $str);
	  # $tag = substr($str, 0, index($str, ' '));
	  last if ($tag eq '+');
	  last SASL if (defined($resp = $self->_process_response($str)));
	}
	if ($tag eq '+') {
	  $str = substr($str, 2);
	  my $saslresp = &$func($i++, $str);
	  last unless defined($saslresp);
	  $self->_send_string($saslresp)->_send_eol;
	  next;
	}
      }
      @list = ();
    } else {
      croak "unknown argument type: $type";
    }
  }
  $self->_send_string(join(' ', @list))->_send_eol if (scalar @list);
  $self->{LastCmdTime} = time;
  if ($self->{Options}{Synchronous}) {
    return $resp if defined($resp);
    return $self->response;
  }
  return $self->{Sequence};
}

=head2 parse_fields $str

Splits the specified C<$str> into fields.  A list reference is
returned contain the individual fields.  Parenthetical clauses are
represented as nested list references of arbitrary depth.  Quoted
strings are stripped of their surrounding quotes and escaped C<\\> and
C<\"> characters are unescaped.

=cut

sub parse_fields {
  my $self = shift;
  my $str = shift;
  return undef unless defined($str);
  my @list;
  my @stack = ([]);

  my $pos = 0;
  my $len = length($str);

  while ($pos < $len) {
    my $c = substr($str, $pos, 1);
    if ($c eq ' ') {
      $pos++;
    } elsif ($c eq '(') {
      push @{$stack[-1]}, [];
      push @stack, $stack[-1]->[-1];
      $pos++;
    } elsif ($c eq ')') {
      pop(@stack);
      $pos++;
    } elsif (substr($str, $pos) =~ /^(\"(?:[^\\\"]|\\\")*\")/) { # qstring
      my $str = substr($1, 1, -1);
      $pos += length $1;
      $str =~ s/\\([\\\"])/$1/g;
      push @{$stack[-1]}, $str;
    } elsif (substr($str, $pos) =~ /^\{(\d+)\}/) { # literal
      $pos += length($1) + 2;
      push @{$stack[-1]}, substr($str, $pos, $1);
      $pos += $1;
    } elsif (substr($str, $pos)
	     =~ /^([^\x00-\x1f\x7f\(\)\{\s\"]+)/) {
      push @{$stack[-1]}, $1;
      $pos += length $1;
    } else {
      croak "parse_fields: eeek! bad parse at position $pos [$str]\n";
    }
  }
  return $stack[0];
}

sub _as_astring {
  my $self = shift;
  my $str = shift;
  my $type = 0;

  my $len = length $str;

  if (($len > 1024) || ($str =~ /[\x00\x0a\x0d\x80-\xff]/)) { # literal
    return [($len, $str)];
  } elsif ($str =~ /[\"\\\x01-\x20\x22\x25\x28-\x2a\{]/) { # qstring
    $str =~ s/([\\\"])/\\$1/g;
    return "\"$str\"";
  } elsif ($str eq '') {
    return '""';
  } else {
    return $str;
  }
}

sub _as_string {
  my $self = shift;
  my $str = shift;
  my $type = 0;

  my $len = length $str;

  if (($len > 1024) || ($str =~ /[\x00\x0a\x0d\"\\\x80-\xff]/)) { # literal
    return [($len, $str)];
  } elsif ($str eq '') {
    return '""';
  } else {
    $str =~ s/([\\\"])/\\$1/g;
    return "\"$str\"";
  }
}

sub _send_string {
  my $self = shift;
  my $str = shift;
  my $len = length $str;

  ($self->{Connection}->syswrite($str, $len) == $len) or return undef;
  $self->debug_print(1, $str) if $self->debug;
  return $self;
}

sub _send_eol {
  my $self = shift;
  ($self->{Connection}->syswrite("\r\n", 2) == 2) or return undef;
  $self->debug_print(1, "eol") if $self->debug;
  return $self;
}

=head2 response

Reads response lines from the server until one of the lines is a
completion response.  For each response, the appropriate callbacks are
triggered.  This is automatically called if the C<Synchronous> option
is on.

=cut

sub response {
  my $self = shift;

  my $response;
  do {
    $response = $self->_process_response($self->getline);
  } until defined($response);

  return $response;
}

sub _process_response {
  my $self = shift;
  my $str = shift;

  # trigger response callback
  my $response = &{$self->{ResponseCallback}}($str);
  return undef unless defined($response);
  $self->debug_print(0, "callback returned $response") if $self->debug;

  # if we get this far it's a completion response, so trigger
  # completion callback

  my $tag = $response->tag;
  if (defined($self->{Pending}{$tag})) {
    &{$self->{Pending}{$tag}}($response);
    delete $self->{Pending}{$tag}; # forget the pending command
  }
  return $response;
}

=head2 getline

Get one 'line' of data from the server, including any literal payloads.

=cut

sub getline {
  my $self = shift;
  my $pstr;

  while (1) {
    my $str = $self->{Connection}->getline or return undef;
    $str =~ s/\r?\n$//;		# strip trailing EOL
    $pstr .= $str;
    last if ($str !~ /\{(\d+)\}$/); # done if no literal at end of string
    my $amt = $1;
    my $literal;
    $self->{Connection}->read($literal, $amt) == $amt or return undef;
    $pstr .= $literal;
  }
  $self->debug_print(0, $pstr) if $self->debug;
  return $pstr;
}

=head2 close_connection

Closes the connection to the server, returning the results of the
operation.

=cut

sub close_connection {
  my $ret = $_[0]->connection->close;
  $_[0]->{Connection} = undef;
  return $ret;
}

=head2 sequence

Returns the sequence number of the last command issued to the server.

=cut

sub sequence { $_[0]->{Sequence} }

=head2 next_sequence

Returns the sequence number that will be assigned to the next command issued.

=cut

sub next_sequence { $_[0]->{Sequence} + 1 }

=head2 pending

Returns a list of sequence numbers for the commands that are still
awaiting a complete response from the server.

The list is sorted numerically.

=cut

sub pending { sort { $a <=> $b } keys %{$_[0]->{Pending}} }

###############################################################################

sub quote {
  my $self = shift;
  my $str = shift;
  return 'nil' unless defined($str);
  $str =~ s/([\\\"])/\\$1/g;
  return "\"$str\"";
}

sub dequote {
  my $self = shift;
  my $str = shift;
  return undef if (lc($str) eq 'nil');
  return $str unless ($str =~ /^\"(.*)\"$/);
  $str = $1;
  $str =~ s/\\(.)/$1/g;
  return $str;
}

###############################################################################

=head2 debug [$boolean]

Returns the value of the debug option for the object.

If C<$boolean> is specified, the debug state is set to the given value.

=cut

sub debug {
  $_[0]->{Options}{Debug} = $_[1] if (defined($_[1]));
  return $_[0]->{Options}{Debug};
}

=head2 debug_print $direction, $text

Prints C<$text> to C<STDERR>, preceded by an indication of traffic
direction, the object reference, and a timestamp. The parameter
C<$direction> is used to indicate the direction of the traffic related
to the debug call.  Use C<0> for data being sent to the server, or
C<1> for data coming from the server.

=cut

sub debug_print {
  my @time = localtime;
  print(STDERR
	$_[1]?'->':'<-',
	" $_[0] ",
	sprintf("%02d:%02d:%02d", @time[2..4]),
	" [", $_[0]->debug_text($_[1], $_[2]), "]\n");
}

=head2 debug_text $text

A stub method intended to be overridden by subclasses.  It provides
subclasses with the ability to make alterations to C<$text> before
being output by C<debug_print> method.  The base class version does no
alteration of C<$text>.

=cut

sub debug_text { $_[2] }

###############################################################################
package Net::xAP::Response;

=head1 RESPONSE OBJECTS

A response object is the data type returned by the C<response> method.
A few convenience routines are provided at the Net::xAP level that are
likely to be common across several protocols.

=head2 new

Creates a new response object.

=cut

sub new {
  my $class = shift;
  my $type = ref($class) || $class;

  my $self = bless {}, $class;

  $self->{Sequence} = 0;
  $self->{Status} = '';
  $self->{Text} = '';

  return $self;
}

=head2 tag

Returns the tag associated with the response object.

=cut

sub tag { $_[0]->{Sequence} }

=head2 status

Returns the command status associated with the response object.  This
will be C<OK>, C<NO>, or C<BAD>.

=cut

sub status { $_[0]->{Status} }

=head2 text

Returns the human readable text assocated with the status of the
response object.

This will typically be overridden by a subclass of the C<xAP> class to
handle things like status codes.

=cut

sub text { $_[0]->{Text} }

=head2 status_code

Returns a list reference containing the response code portion of the
server response.

=cut

sub status_code { $_[0]->{StatusCode} }

###############################################################################

=head1 CAVEATS

With only a few exceptions, the methods provided in this class are
intended for use by developers adding support for additional
protocols.  Don't muck with this level, unless you know what you're
doing.

=head1 AUTHOR

Kevin Johnson E<lt>F<kjj@pobox.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 1997-1999 Kevin Johnson <kjj@pobox.com>.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
