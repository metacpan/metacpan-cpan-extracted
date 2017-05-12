# $Id: Filter-IRC.pm,v 1.3 1999/12/12 11:48:07 dennis Exp $
#
# POE::Filter::IRC, by Dennis Taylor <dennis@funkplanet.com>
# Modified for P10 Protocol by Chris Williams
#
# This module may be used, modified, and distributed under the same
# terms as Perl itself. Please see the license that came with your Perl
# distribution for details.
#

package POE::Filter::IRC::P10;

use strict;
use Carp;
use vars qw($VERSION);

$VERSION = '0.998';

# Create a new, empty POE::Filter::IRC object.
sub new {
  my $class = shift;
  my %args = @_;

  bless {}, $class;
}


# Set/clear the 'debug' flag.
sub debug {
  my $self = shift;
  $self->{'debug'} = $_[0] if @_;
  return $self->{'debug'};
}


# For each line of raw IRC input data that we're fed, spit back the
# appropriate IRC events.
sub get {
  my ($self, $raw) = @_;
  my $events = [];
  my %token2cmd = ('AC' => 'ACCOUNT', 'AD' => 'ADMIN', 'LL' => 'ASLL', 'A' => 'AWAY', 'B' => 'BURST', 'CM' => 'CLEARMODE', 'CLOSE' => 'CLOSE', 'CN' => 'CNOTICE', 'CO' => 'CONNECT', 'CP' => 'CPRIVMSG', 'C' => 'CREATE', 'DE' => 'DESTRUCT', 'DS' => 'DESYNCH', 'DIE' => 'DIE', 'DNS' => 'DNS', 'EB' => 'END_OF_BURST', 'EA' => 'EOB_ACK', 'Y' => 'ERROR', 'GET' => 'GET', 'GL' => 'GLINE', 'HASH' => 'HASH', 'HELP' => 'HELP', 'F' => 'INFO', 'I' => 'INVITE', 'ISON' => 'ISON', 'J' => 'JOIN', 'JU' => 'JUPE', 'K' => 'KICK', 'D' => 'KILL', 'LI' => 'LINKS', 'LIST' => 'LIST', 'LU' => 'LUSERS', 'MAP' => 'MAP', 'M' => 'MODE', 'MO' => 'MOTD', 'E' => 'NAMES', 'N' => 'NICK', 'O' => 'NOTICE', 'OPER' => 'OPER', 'OM' => 'OPMODE', 'L' => 'PART', 'PA' => 'PASS', 'G' => 'PING', 'Z' => 'PONG', 'POST' => 'POST', 'P' => 'PRIVMSG', 'PRIVS' => 'PRIVS', 'PROTO' => 'PROTO', 'Q' => 'QUIT', 'REHASH' => 'REHASH', 'RESET' => 'RESET', 'RESTART' => 'RESTART', 'RI' => 'RPING', 'RO' => 'RPONG', 'S' => 'SERVER', 'SET' => 'SET', 'SE' => 'SETTIME', 'U' => 'SILENCE', 'SQ' => 'SQUIT', 'R' => 'STATS', 'TI' => 'TIME', 'T' => 'TOPIC', 'TR' => 'TRACE', 'UP' => 'UPING', 'USER' => 'USER', 'USERHOST' => 'USERHOST', 'USERIP' => 'USERIP', 'V' => 'VERSION', 'WC' => 'WALLCHOPS', 'WA' => 'WALLOPS', 'WU' => 'WALLUSERS', 'WV' => 'WALLVOICES', 'H' => 'WHO', 'W' => 'WHOIS', 'X' => 'WHOWAS');

  foreach my $line (@$raw) {
    warn "<<< $line\n" if $self->{'debug'};
    next unless $line =~ /\S/;

    if ($line =~ /^(\S+) G (.+)$/) {
      push @$events, { name => 'ping', args => [$1] };

      # PRIVMSG and NOTICE
    } elsif ($line =~ /^(\S+) +(P|O) +(\S+) +(.+)$/) {
      if ($2 eq 'O') {
	push @$events, { name => 'notice',
			 args => [$1, [split /,/, $3], _decolon( $4 )] };

	# Using tr/// to count characters here tickles a bug in 5.004. Suck.
      } elsif (index( $3, '#' ) >= 0 or index( $3, '&' ) >= 0
	       or index( $3, '+' ) >= 0) {
	push @$events, { name => 'public',
			 args => [$1, [split /,/, $3], _decolon( $4 )] };

      } else {
	# Need a fix here for nick\@server format i think
	push @$events, { name => 'msg',
			 args => [$1, [split /,/, $3], _decolon( $4 )] };
      }

      # Numeric events
    } elsif ($line =~ /^(\S+) +(\d+) +(\S+) +(.+)$/) {
      push @$events, { name => $2, args => [$1, _decolon( $4 )] };

      # MODE... just split the args and pass them wholesale.
    } elsif ($line =~ /^(\S+) +(M|OM) +(\S+) +(.+)$/) {
      push @$events, { name => lc $token2cmd{$2}, args => [$1, $3, split(/\s+/, $4)] };

    } elsif ($line =~ /^(\S+) +K +(\S+) +(\S+) +(.+)$/) {
      push @$events, { name => 'kick', args => [$1, $2, $3, _decolon( $4 )] };

    } elsif ($line =~ /^(\S+) +T +(\S+) +(.+)$/) {
      push @$events, { name => 'topic', args => [$1, $2, _decolon( $3 )] };

    } elsif ($line =~ /^(\S+) +I +(\S+) +(.+)$/) {
      push @$events, { name => 'invite', args => [$1, $2, _decolon( $3 )] };

    } elsif ($line =~ /^SERVER +(.+)$/) {
      push @$events, { name => 'server_link', args => [ split(/ /,$1,8), _decolon( substr($1,index($1," :")) ) ] };

      # NICK, QUIT, JOIN, PART, possibly more?
    } elsif ($line =~ /^(\S+) +(\S+) +(.+)$/) {
      unless (grep {$_ eq lc $2} qw(n j q l z r eb b s sq w ac cm gl c ds d)) {
	warn "*** ACCIDENTAL MATCH: $2\n";
	warn "*** Accident line: $line\n";
      }
      push @$events, { name => lc $token2cmd{$2}, args => [$1, _decolon( $3 )] };

      # We'll call this 'snotice' (server notice), for lack of a better name.
    } elsif ($line =~ /^NOTICE +\S+ +(.+)$/) {
      push @$events, { name => 'snotice', args => [_decolon( $1 )] };

      # Eeek.
    } elsif ($line =~ /^ERROR +(.+)$/) {

      # If nothing matches, barf and keep reading. Seems reasonable.
      # I'll reuse the famous "Funky parse case!" error from Net::IRC,
      # just for a sense of historical continuity.
    } elsif ($line =~ /^(\S+) +(EB|EA)/) {
      push @$events, { name => lc $token2cmd{$2}, args => [_decolon( $1 )] };
    } elsif ($line =~ /^PASS +(\S+)$/) {
      push @$events, { name => 'pass', args => [_decolon( $1 )] };
    } else {
      warn "*** Funky parse case!\nFunky line: \"$line\"\n";
    }
  }

  return $events;
}


# Strips superfluous colons from the beginning of text chunks. I can't
# believe that this ludicrous protocol can handle ":foo" and ":foo bar"
# in a totally different manner.
sub _decolon ($) {
  my $line = shift;

#  This is very, very, wrong.
#  if ($line =~ /^:.*\s.*$/) {
#	$line = substr $line, 1;
#  }

  $line =~ s/^://;
  return $line;
}


# This sub is so useless to implement that I won't even bother.
sub put {
  croak "Call to unimplemented subroutine POE::Filter::IRC->put()";
}


1;


__END__

=head1 NAME

POE::Filter::IRC::P10 -- A POE-based parser for the IRC protocol, hacked for P10 protocol.

=head1 SYNOPSIS

    my $filter = POE::Filter::IRC::P10->new();
    my @events = @{$filter->get( [ @lines ] )};

=head1 DESCRIPTION

POE::Filter::IRC::P10 takes lines of raw IRC input and turns them into
weird little data structures, suitable for feeding to
POE::Component::IRC::Service::P10. They look like this:

    { name => 'event name', args => [ some info about the event ] }

=head1 METHODS

=over

=item new

Creates a new POE::Filter::IRC::P10 object. Duh. :-)   Takes no arguments.

=item get

Takes an array reference full of lines of raw IRC text. Returns an
array reference of processed, pasteurized events.

=item put

There is no "put" method. That would be kinda silly for this filter,
don't you think?

=item debug

Enable or disable debugging information.

=back

=head1 AUTHOR

Dennis "fimmtiu" Taylor, E<lt>dennis@funkplanet.comE<gt>.

Hacked for P10 by Chris "BinGOs" Williams E<lt>chris@Bingosnet.co.ukE<gt>

=head1 SEE ALSO

The documentation for POE and POE::Component::IRC and POE::Component::IRC::Service.

P10 Specification - http://www.xs4all.nl/~carlo17/irc/P10.html
		    http://www.xs4all.nl/~beware3/irc/bewarep10.html

=cut
