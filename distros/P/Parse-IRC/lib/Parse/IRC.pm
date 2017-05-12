package Parse::IRC;
$Parse::IRC::VERSION = '1.22';
#ABSTRACT: A parser for the IRC protocol.

# We export some stuff
require Exporter;
@ISA = qw[Exporter];
@EXPORT = qw[parse_irc];

use strict;
use warnings;
use File::Basename qw[fileparse];

my $g = {
  space			=> qr/\x20+/o,
  trailing_space	=> qr/\x20*/o,
};

my $irc_regex = qr/^
  (?:
    \x3a                #  : comes before hand
    (\S+)               #  [prefix]
    $g->{'space'}       #  Followed by a space
  )?                    # but is optional.
  (
    \d{3}|[a-zA-Z]+     #  [command]
  )                     # required.
  (?:
    $g->{'space'}       # Strip leading space off [middle]s
    (                   # [middle]s
      (?:
        [^\x00\x0a\x0d\x20\x3a]
        [^\x00\x0a\x0d\x20]*
      )                 # Match on 1 of these,
      (?:
        $g->{'space'}
        [^\x00\x0a\x0d\x20\x3a]
        [^\x00\x0a\x0d\x20]*
      )*           # then match on 0-13 of these,
    )
  )?                    # otherwise dont match at all.
  (?:
    $g->{'space'}\x3a   # Strip off leading spacecolon for [trailing]
    ([^\x00\x0a\x0d]*)	# [trailing]
  )?                    # [trailing] is not necessary.
  $g->{'trailing_space'}
$/x;

# the magic cookie jar
my %dcc_types = (
    qr/^(?:CHAT|SEND)$/ => sub {
        my ($nick, $type, $args) = @_;
        my ($file, $addr, $port, $size);
        return if !(($file, $addr, $port, $size) = $args =~ /^(".+"|[^ ]+) +([0-9a-fA-F:]+) +(\d+)(?: +(\d+))?/);

        if ($file =~ s/^"//) {
            $file =~ s/"$//;
            $file =~ s/\\"/"/g;
        }
        $file = fileparse($file);

        return (
            $port,
            {
                nick => $nick,
                type => $type,
                file => $file,
                size => $size,
                addr => $addr,
                port => $port,
            },
            $file,
            $size,
            $addr,
        );
    },
    qr/^(?:ACCEPT|RESUME)$/ => sub {
        my ($nick, $type, $args) = @_;
        my ($file, $port, $position);
        return if !(($file, $port, $position) = $args =~ /^(".+"|[^ ]+) +(\d+) +(\d+)/);

        $file =~ s/^"|"$//g;
        $file = fileparse($file);

        return (
            $port,
            {
                nick => $nick,
                type => $type,
                file => $file,
                size => $position,
                port => $port,
            },
            $file,
            $position,
        );
    },
);

sub parse_irc {
  my $string = shift || return;
  return __PACKAGE__->new(@_)->parse($string);
}

sub new {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  return bless \%opts, $package;
}

sub parse {
  my $self = shift;
  my $raw_line = shift || return;
  $raw_line =~ s/(\x0D\x0A?|\x0A\x0D?)$//;
  if ( my($prefix, $command, $middles, $trailing) = $raw_line =~ m/$irc_regex/ ) {
      my $event = { raw_line => $raw_line };
      $event->{'prefix'} = $prefix if $prefix;
      $event->{'command'} = uc $command;
      $event->{'params'} = [] if ( defined ( $middles ) || defined ( $trailing ) );
      push @{$event->{'params'}}, (split /$g->{'space'}/, $middles) if defined ( $middles );
      push @{$event->{'params'}}, $trailing if defined( $trailing );
      if ( $self->{ctcp} and $event->{'command'} =~ /^(PRIVMSG|NOTICE)$/ and $event->{params}->[1] =~ tr/\001// ) {
        return $self->_get_ctcp( $event );
      }
      if ( $self->{public} and $event->{'command'} eq 'PRIVMSG' and $event->{'params'}->[0] =~ /^(\x23|\x26)/ ) {
	$event->{'command'} = 'PUBLIC';
      }
      return $event;
  }
  else {
      warn "Received line $raw_line that is not IRC protocol\n" if $self->{debug};
  }
  return;
}

sub _get_ctcp {
    my ($self, $line) = @_;

    # Is this a CTCP request or reply?
    my $ctcp_type = $line->{command} eq 'PRIVMSG' ? 'CTCP' : 'CTCPREPLY';

    # CAPAP IDENTIFY-MSG is only applied to ACTIONs
    my ($msg, $identified) = ($line->{params}->[1], undef);
    ($msg, $identified) = _split_idmsg($msg) if $self->{identifymsg} && $msg =~ /^.ACTION/;

    my $events;
    my ($ctcp, $text) = _ctcp_dequote($msg);

    if (!defined $ctcp) {
        warn "Received malformed CTCP message: $msg\n" if $self->{debug};
        return $events;
    }

    my $nick = defined $line->{prefix} ? (split /!/, $line->{prefix})[0] : undef;

    # We only process the first CTCP. The only people who send multiple ones
    # are those who are trying to flood our outgoing queue anyway (e.g. by
    # having us reply to 20 VERSION requests at a time).
    my ($name, $args);
    CTCP: for my $string ($ctcp->[0]) {
        if (!(($name, $args) = $string =~ /^(\w+)(?: +(.*))?/)) {
            defined $nick
                ? do { warn "Received malformed CTCP message from $nick: $string\n" if $self->{debug} }
                : do { warn "Trying to send malformed CTCP message: $string\n" if $self->{debug} }
            ;
            last CTCP;
        }

        if (lc $name eq 'dcc') {
            my ($dcc_type, $rest);

            if (!(($dcc_type, $rest) = $args =~ /^(\w+) +(.+)/)) {
                defined $nick
                    ? do { warn "Received malformed DCC request from $nick: $args\n" if $self->{debug} }
                    : do { warn "Trying to send malformed DCC request: $args\n" if $self->{debug} }
                ;
                last CTCP;

            }
            $dcc_type = uc $dcc_type;

            my ($handler) = grep { $dcc_type =~ /$_/ } keys %dcc_types;
            if (!$handler) {
                warn "Unhandled DCC $dcc_type request: $rest\n" if $self->{debug};
                last CTCP;
            }

            my @dcc_args = $dcc_types{$handler}->($nick, $dcc_type, $rest);
            if (!@dcc_args) {
                defined $nick
                    ? do { warn "Received malformed DCC $dcc_type request from $nick: $rest\n" if $self->{debug} }
                    : do { warn "Trying to send malformed DCC $dcc_type request: $rest\n" if $self->{debug} }
                ;
                last CTCP;
            }

            $events = {
                prefix => $line->{prefix},
                command => 'DCC_REQUEST',
                params => [
                    $dcc_type,
                    @dcc_args,
                ],
                raw_line => $line->{raw_line},
            };
        }
        else {
            $events = {
                command => $ctcp_type . '_' . uc $name,
                prefix => $line->{prefix},
                params => [
                    $line->{params}->[0],
                    (defined $args ? $args : ''),
                    (defined $identified ? $identified : () ),
                ],
                raw_line => $line->{raw_line},
            };
        }
    }

    # XXX: I'm not quite sure what this is for, but on FreeNode it adds an
    # extra bogus event and displays a debug message, so I have disabled it.
    # FreeNode precedes PRIVMSG and CTCP ACTION messages with '+' or '-'.
    #if ($text && @$text) {
    #    my $what;
    #    ($what) = $line->{raw_line} =~ /^(:[^ ]+ +\w+ +[^ ]+ +)/
    #        or warn "What the heck? '".$line->{raw_line}."'\n" if $self->{debug};
    #    $text = (defined $what ? $what : '') . ':' . join '', @$text;
    #    $text =~ s/\cP/^P/g;
    #    warn "CTCP: $text\n" if $self->{debug};
    #    push @$events, @{ $self->{_ircd}->get([$text]) };
    #}

    return $events;
}

sub _split_idmsg {
    my ($line) = @_;
    my ($identified, $msg) = split //, $line, 2;
    $identified = $identified eq '+' ? 1 : 0;
    return $msg, $identified;
}

# Splits a message into CTCP and text chunks. This is gross. Most of
# this is also stolen from Net::IRC, but I (fimm) wrote that too, so it's
# used with permission. ;-)
sub _ctcp_dequote {
    my ($msg) = @_;
    my (@chunks, $ctcp, $text);

    # CHUNG! CHUNG! CHUNG!

    if (!defined $msg) {
        die 'Not enough arguments to Parse::IRC::_ctcp_dequote';
    }

    # Strip out any low-level quoting in the text.
    $msg = _low_dequote( $msg );

    # Filter misplaced \001s before processing... (Thanks, tchrist!)
    substr($msg, rindex($msg, "\001"), 1, '\\a')
        if ($msg =~ tr/\001//) % 2 != 0;

    return if $msg !~ tr/\001//;

    @chunks = split /\001/, $msg;
    shift @chunks if !length $chunks[0]; # FIXME: Is this safe?

    for (@chunks) {
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

    return ($ctcp, $text);
}

# Quotes a string in a low-level, protocol-safe, utterly brain-dead
# fashion. Returns the quoted string.
sub _low_quote {
    my ($line) = @_;
    my %enquote = ("\012" => 'n', "\015" => 'r', "\0" => '0', "\cP" => "\cP");

    if (!defined $line) {
        die 'Not enough arguments to Parse::IRC->_low_quote';
    }

    if ($line =~ tr/[\012\015\0\cP]//) { # quote \n, \r, ^P, and \0.
        $line =~ s/([\012\015\0\cP])/\cP$enquote{$1}/g;
    }

    return $line;
}

# Does low-level dequoting on CTCP messages. I hate this protocol.
# Yes, I copied this whole section out of Net::IRC.
sub _low_dequote {
    my ($line) = @_;
    my %dequote = (n => "\012", r => "\015", 0 => "\0", "\cP" => "\cP");

    if (!defined $line) {
        die 'Not enough arguments to Parse::IRC->_low_dequote';
    }

    # dequote \n, \r, ^P, and \0.
    # Thanks to Abigail (abigail@foad.org) for this clever bit.
    if ($line =~ tr/\cP//) {
        $line =~ s/\cP([nr0\cP])/$dequote{$1}/g;
    }

    return $line;
}

q[Operation Blackbriar];

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::IRC - A parser for the IRC protocol.

=head1 VERSION

version 1.22

=head1 SYNOPSIS

General usage:

  use strict;
  use Parse::IRC;

  # Functional interface

  my $hashref = parse_irc( $irc_string );

  # OO interface

  my $irc_parser = Parse::IRC->new();

  my $hashref = $irc_parser->parse( $irc_string );

Using Parse::IRC in a simple IRC bot:

  # A simple IRC bot using Parse::IRC

  use strict;
  use IO::Socket;
  use Parse::IRC;

  my $parser = Parse::IRC->new( public => 1 );

  my %dispatch = ( 'ping' => \&irc_ping, '001' => \&irc_001, 'public' => \&irc_public );

  # The server to connect to and our details.
  my $server = "irc.perl.moo";
  my $nick = "parseirc$$";
  my $login = "simple_bot";

  # The channel which the bot will join.
  my $channel = "#IRC.pm";

  # Connect to the IRC server.
  my $sock = new IO::Socket::INET(PeerAddr => $server,
                                  PeerPort => 6667,
                                  Proto => 'tcp') or
                                    die "Can't connect\n";

  # Log on to the server.
  print $sock "NICK $nick\r\n";
  print $sock "USER $login 8 * :Perl IRC Hacks Robot\r\n";

  # Keep reading lines from the server.
  while (my $input = <$sock>) {
    $input =~ s/\r\n//g;
    my $hashref = $parser->parse( $input );
    SWITCH: {
          my $type = lc $hashref->{command};
          my @args;
          push @args, $hashref->{prefix} if $hashref->{prefix};
          push @args, @{ $hashref->{params} };
          if ( defined $dispatch{$type} ) {
            $dispatch{$type}->(@args);
            last SWITCH;
          }
          print STDOUT join( ' ', "irc_$type:", @args ), "\n";
    }
  }

  sub irc_ping {
    my $server = shift;
    print $sock "PONG :$server\r\n";
    return 1;
  }

  sub irc_001 {
    print STDOUT "Connected to $_[0]\n";
    print $sock "JOIN $channel\r\n";
    return 1;
  }

  sub irc_public {
    my ($who,$where,$what) = @_;
    print "$who -> $where -> $what\n";
    return 1;
  }

=head1 DESCRIPTION

Parse::IRC provides a convenient way of parsing lines of text conforming to the IRC
protocol ( see RFC1459 or RFC2812 ).

=head1 FUNCTION INTERFACE

Using the module automagically imports 'parse_irc' into your namespace.

=over

=item C<parse_irc>

Takes a string of IRC protcol text. Returns a hashref on success or undef on failure.
See below for the format of the hashref returned.

=back

=head1 OBJECT INTERFACE

=head2 CONSTRUCTOR

=over

=item C<new>

Creates a new Parse::IRC object. One may specify C<< debug => 1 >> to enable warnings about non-IRC
protcol lines. Specify C<< public => 1 >> to enable the automatic conversion of privmsgs targeted at
channels to C<public> instead of C<privmsg>. Specify C<< ctcp => 1 >> to enable automatic conversion
of privmsgs and notices with CTCP/DCC type encoding to C<ctcp>, C<ctcpreply> and C<dcc_request>.

=back

=head2 METHODS

=over

=item C<parse>

Takes a string of IRC protcol text. Returns a hashref on success or undef on failure.
The hashref contains the following fields:

  prefix
  command
  params ( this is an arrayref )
  raw_line

For example, if the filter receives the following line, the following hashref is produced:

  LINE: ':moo.server.net 001 lamebot :Welcome to the IRC network lamebot'

  HASHREF: {
	     prefix   => ':moo.server.net',
	     command  => '001',
	     params   => [ 'lamebot', 'Welcome to the IRC network lamebot' ],
	     raw_line => ':moo.server.net 001 lamebot :Welcome to the IRC network lamebot',
	   }

=back

=head1 KUDOS

Based on code originally developed by Jonathan Steinert and Dennis Taylor

=head1 SEE ALSO

L<POE::Filter::IRCD>

L<http://www.faqs.org/rfcs/rfc1459.html>

L<http://www.faqs.org/rfcs/rfc2812.html>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Chris Williams, Jonathan Steinert and Dennis Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
