#!/usr/bin/perl -w
#
# $Id: eliza.pl,v 3.5 2005/02/19 13:26:46 chris Exp $
#
# This is an adaption of Dennis Taylor's test.pl.  It combines a very
# simple bot with Chatbot::Eliza to make something fairly annoying.
# -- Rocco Caputo, <troc+pci@netrus.net>

use strict;

use POE::Kernel;
use POE::Session;
use POE::Component::IRC 3.4;
use Chatbot::Eliza;


my $pid = $$; substr($pid, 0, 1) = '' while length($pid) > 3;
my $nick = 'eliza' . $pid;
my $name = 'eliza' . $pid;

my $eliza = Chatbot::Eliza->new();

# This gets executed as soon as the kernel sets up this session.
sub _start {
  my ($kernel, $session) = @_[KERNEL, SESSION];

  $_[HEAP] = $_[ARG0];

  # Uncomment this to turn on more verbose POE debugging information.
  # $session->option( trace => 1 );

  # Ask the IRC component to send us all IRC events it receives. This
  # is the easy, indiscriminate way to do it.
  $_[HEAP]->yield( 'register', 'all');

  # Setting Debug to 1 causes P::C::IRC to print all raw lines of text
  # sent to and received from the IRC server. Very useful for debugging.
  $_[HEAP]->yield( 'connect', { }
	       );
}


# After we successfully log into the IRC server, join a channel.
sub irc_001 {
  my ($kernel) = $_[KERNEL];

  $_[HEAP]->yield( 'mode', $nick, '+i' );
  $_[HEAP]->yield( 'join', $ARGV[2] || '#IRC.pm' );
  $_[HEAP]->yield( 'away',
                 'JOSHUA SCHACTER IST MEIN GELEESCHAUMGUMMIRING DER LIEBE!' );
}


sub _stop {
  my ($kernel) = $_[KERNEL];

  print "Control session stopped.\n";
  $_[HEAP]->call( 'quit', 'Neenios on ice!' );
}


sub irc_disconnected {
  my ($server) = $_[ARG0];
  print "Lost connection to server $server.\n";
}


sub irc_error {
  my $err = $_[ARG0];
  print "Server error occurred! $err\n";
}


sub irc_socketerr {
  my $err = $_[ARG0];
  print "Couldn't connect to server: $err\n";
}


sub irc_kick {
  my ($kernel, $who, $where, $isitme, $reason) = @_[KERNEL, ARG0 .. ARG4];
  if ($isitme eq $nick) {
    print "Kicked from $where by $who: $reason\n";

    # Uncomment for auto-rejoin.  Nasty, evil, don't do it.
    # $kernel->post( 'test', 'join', $where );
  }

}

sub irc_public {
  my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0 .. ARG2];
  my $nick = (split /!/, $who)[0];
  print "<$nick:@{$where}[0]> $msg\n";
  $_[HEAP]->yield( privmsg => $where,
                 $eliza->transform($msg)     # Filter it through a Chatbot.
               );
}


# here's where execution starts.

my ($object) = POE::Component::IRC->spawn(
  				      Debug    => 1,
				      Nick     => $nick,
				      Server   => $ARGV[0] ||
				                  'irc.rhizomatic.net',
				      Port     => $ARGV[1] || 6667,
				      Username => $name,
				      Ircname  => 'Ask me about my colon!' ) or
  die "Can't instantiate new IRC component!\n";

POE::Session->create( package_states => [ 'main' =>
                   [ qw( _start _stop irc_001 irc_kick irc_disconnected
			 irc_error irc_socketerr irc_public
                       )
                   ], ],
		   args => [ $object ],
                 );
$poe_kernel->run();

exit 0;

