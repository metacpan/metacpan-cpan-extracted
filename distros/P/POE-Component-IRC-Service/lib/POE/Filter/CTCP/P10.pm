# $Id: Filter-CTCP.pm,v 1.3 1999/12/12 11:48:07 dennis Exp $
#
# POE::Filter::CTCP, by Dennis Taylor <dennis@funkplanet.com>
#
# This module may be used, modified, and distributed under the same
# terms as Perl itself. Please see the license that came with your Perl
# distribution for details.
#

package POE::Filter::CTCP::P10;

use strict;
use Carp;
use File::Basename ();
use POE::Filter::IRC::P10;


# Create a new, empty POE::Filter::CTCP::P10 object.
sub new {
  my $class = shift;
  my %args = @_;

  my $self = { 'irc_filter' => POE::Filter::IRC::P10->new() };
  bless $self, $class;
}


# Set/clear the 'debug' flag.
sub debug {
  my $self = shift;
  $self->{'debug'} = $_[0] if @_;
  return( $self->{'debug'} );
}


# For each line of raw CTCP input data that we're fed, spit back the
# appropriate CTCP and normal message events.
sub get {
  my ($self, $lineref) = @_;
  my ($who, $type, $where, $ctcp, $text, $name, $args);
  my $events = [];

 LINE:
  foreach my $line (@$lineref) {
    ($who, $type, $where, $ctcp, $text) = _ctcp_dequote( $line );

    foreach (@$ctcp) {
      ($name, $args) = $_ =~ /^(\w+)(?: (.*))?/
	or do { warn "Received malformed CTCP message: \"$_\""; next LINE; };
      if (lc $name eq 'dcc') {
	$args =~ /^(\w+) (\S+) (\d+) (\d+)(?: (\d+))?$/
	  or do { warn "Received malformed DCC request: \"$_\""; next LINE; };
	my $basename = File::Basename::basename( $2 );
	push @$events, { name => 'dcc_request',
			 args => [ $who, uc $1, $4, { open => undef,
						      nick => $who,
						      type => uc $1,
						      file => $basename,
						      size => $5,
						      done => 0,
						      addr => $3,
						      port => $4,
						    }, $basename, $5 ]
		       };

      } else {
	push @$events, { name => $type . '_' . lc $name,
			 args => [ $who, [split /,/, $where],
				   (defined $args ? $args : '') ]
		       };
      }
    }

    if ($text and @$text > 0) {
      $line =~ /^(\S+ +\w+ +\S+ +)/ or warn "What the heck? \"$line\"";
      $text = $1 . ':' . join '', @$text;
      $text =~ s/\cP/^P/g;
      warn "CTCP: $text\n" if $self->{'debug'};
      push @$events, @{$self->{irc_filter}->get( [$text] )};
    }
  }

  return $events;
}


# For each line of text we're fed, spit back a CTCP-quoted version of
# that line.
sub put {
  my ($self, $lineref) = @_;
  my $quoted = [];

  foreach my $line (@$lineref) {
    push @$quoted, _ctcp_quote( $line );
  }

  return $quoted;
}


# Quotes a string in a low-level, protocol-safe, utterly brain-dead
# fashion. Returns the quoted string.
sub _low_quote {
  my $line = shift;
  my %enquote = ("\012" => 'n', "\015" => 'r', "\0" => '0', "\cP" => "\cP");

  unless (defined $line) {
    die "Not enough arguments to POE::Filter::CTCP->_low_quote";
  }

  if ($line =~ tr/[\012\015\0\cP]//) { # quote \n, \r, ^P, and \0.
    $line =~ s/([\012\015\0\cP])/\cP$enquote{$1}/g;
  }

  return $line;
}


# Does low-level dequoting on CTCP messages. I hate this protocol.
# Yes, I copied this whole section out of Net::IRC.
sub _low_dequote {
  my $line = shift;
  my %dequote = (n => "\012", r => "\015", 0 => "\0", "\cP" => "\cP");

  unless (defined $line) {
    die "Not enough arguments to POE::Filter::CTCP->_low_dequote";
  }

  # Thanks to Abigail (abigail@foad.org) for this clever bit.
  if ($line =~ tr/\cP//) {	# dequote \n, \r, ^P, and \0.
    $line =~ s/\cP([nr0\cP])/$dequote{$1}/g;
  }

  return $line;
}


# Properly CTCP-quotes a message. Whoop.
sub _ctcp_quote {
  my $line = shift;

  $line = _low_quote( $line );
#  $line =~ s/\\/\\\\/g;
  $line =~ s/\001/\\a/g;

  return "\001" . $line . "\001";
}


# Splits a message into CTCP and text chunks. This is gross. Most of
# this is also stolen from Net::IRC, but I wrote that too, so it's
# used with permission. ;-)
sub _ctcp_dequote {
  my $line = shift;
  my (@chunks, $ctcp, $text, $who, $type, $where, $msg);

  # CHUNG! CHUNG! CHUNG!

  unless (defined $line) {
    die "Not enough arguments to POE::Filter::CTCP->_ctcp_dequote";
  }

  # Strip out any low-level quoting in the text.
  $line = _low_dequote( $line );

  # Filter misplaced \001s before processing... (Thanks, tchrist!)
  substr($line, rindex($line, "\001"), 1) = '\\a'
    unless ($line =~ tr/\001//) % 2 == 0;

  return unless $line =~ tr/\001//;

  ($who, $type, $where, $msg) = ($line =~ /^(\S+) +(\w+) +(\S+) +:?(.*)$/)
    or return;
  @chunks = split /\001/, $msg;
  shift @chunks unless length $chunks[0]; # FIXME: Is this safe?

  foreach (@chunks) {
    # Dequote unnecessarily quoted chars, and convert escaped \'s and ^A's.
    s/\\([^\\a])/$1/g;
    s/\\\\/\\/g;
    s/\\a/\001/g;
  }

  # If the line begins with a control-A, the first chunk is a CTCP
  # message. Otherwise, it starts with text and alternates with CTCP
  # messages. Really stupid protocol.

  if ($msg =~ /^\001/) {
    push @$ctcp, shift @chunks;
  }

  while (@chunks) {
    push @$text, shift @chunks;
    push @$ctcp, shift @chunks if @chunks;
  }

  # Is this a CTCP request or reply?
  if ($type eq 'P') {
    $type = 'ctcp';
  } else {
    $type = 'ctcpreply';
  }

  return ($who, $type, $where, $ctcp, $text);
}


1;

__END__

=head1 NAME

POE::Filter::CTCP::P10 -- A POE-based parser for the IRC protocol, fixed to work with P10 protocol.

=head1 SYNOPSIS

  my $filter = POE::Filter::CTCP::P10->new();
  my @events = @{$filter->get( [ @lines ] )};
  my @msgs = @{$filter->put( [ @messages ] )};

=head1 DESCRIPTION

POE::Filter::CTCP::P10 converts normal text into thoroughly CTCP-quoted
messages, and transmogrifies CTCP-quoted messages into their normal,
sane components. Rather what you'd expect a filter to do.

A note: the CTCP protocol sucks bollocks. If I ever meet the fellow who
came up with it, I'll shave their head and tattoo obscenities on it.
Just read the "specification" at
http://cs-pub.bu.edu/pub/irc/support/ctcp.spec and you'll hopefully see
what I mean. Quote this, quote that, quote this again, all in different
and weird ways... and who the hell needs to send mixed CTCP and text
messages? WTF? It looks like it's practically complexity for
complexity's sake -- and don't even get me started on the design of the
DCC protocol! Anyhow, enough ranting. Onto the rest of the docs...

=head1 METHODS

=over

=item new

Creates a new POE::Filter::CTCP::P10 object. Duh. :-)   Takes no arguments.

=item get

Takes an array reference containing one or more lines of CTCP-quoted
text. Returns an array reference of processed, pasteurized events.

=item put

Takes an array reference of CTCP messages to be properly quoted. This
doesn't support CTCPs embedded in normal messages, which is a
brain-dead hack in the protocol, so do it yourself if you really need
it. Returns an array reference of the quoted lines for sending.

=item debug

Enables or disables debugging information.

=back

=head1 AUTHOR

Dennis "fimmtiu" Taylor, E<lt>dennis@funkplanet.comE<gt>.

Hacked for P10 by Chris "BinGOs" Williams E<lt>chris@bingosnet.co.ukE<gt>

=head1 SEE ALSO

The documentation for POE and POE::Component::IRC and POE::Component::IRC::Service.

P10 Specification - http://www.xs4all.nl/~carlo17/irc/P10.html
                    http://www.xs4all.nl/~beware3/irc/bewarep10.html

=cut
