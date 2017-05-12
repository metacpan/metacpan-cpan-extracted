#!/usr/bin/perl -w
#
# $Id: dcctest.pl,v 3.5 2005/02/19 13:26:46 chris Exp $
#
# This simple test program should give you an idea of how a basic
# POE::Component::IRC script fits together.
# -- dennis taylor, <dennis@funkplanet.com>

use strict;
use POE::Kernel;
use POE::Session;
use POE::Component::IRC;

my $nick = "spleen" . ($$ % 1000);


# This gets executed as soon as the kernel sets up this session.
sub _start {
  my ($kernel, $session) = @_[KERNEL, SESSION];

  # Ask the IRC component to send us all IRC events it receives. This
  # is the easy, indiscriminate way to do it.
  $kernel->post( 'test', 'register', 'all');

  # Setting Debug to 1 causes P::C::IRC to print all raw lines of text
  # sent to and received from the IRC server. Very useful for debugging.
  $kernel->post( 'test', 'connect', { Debug    => 1,
				      Nick     => $nick,
                                      Server   => $ARGV[0] || 'irc.phreeow.net',
				      Port     => $ARGV[1] || 6667,
				      Username => 'neenio',
				      Ircname  => 'Ask me about my colon!', }
	       );
}


# After we successfully log into the IRC server, join a channel.
sub irc_001 {
  my ($kernel) = $_[KERNEL];

  $kernel->post( 'test', 'mode', $nick, '+i' );
  $kernel->post( 'test', 'join', '#IRC.pm' );
  $kernel->post( 'test', 'away', 'JOSHUA SCHACTER IS MY SLIPPERY TURGID ZUCCHINI OF LUST' );
}


sub irc_dcc_done {
  my ($magic, $nick, $type, $port, $file, $size, $done) = @_[ARG0 .. ARG6];
  print "DCC $type to $nick ($file) done: $done bytes transferred.\n",
}


sub irc_dcc_error {
  my ($err, $nick, $type, $file) = @_[ARG0 .. ARG2, ARG4];
  print "DCC $type to $nick ($file) failed: $err.\n",
}


sub _stop {
  my ($kernel) = $_[KERNEL];

  print "Control session stopped.\n";
  $kernel->call( 'test', 'quit', 'Neenios on ice!' );
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
  my ($who, $where, $isitme, $reason) = @_[ARG0 .. ARG4];

  print "Kicked from $where by $who: $reason\n" if $isitme eq $nick;
}


sub irc_public {
  my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0 .. ARG2];
  $who = (split /!/, $who)[0];

  print "<$who:@{$where}[0]> $msg\n";

  if ($msg =~ /quit/i) {
    $kernel->post( 'test', 'quit', "Requested by $who" );

  } elsif ($msg =~ /send/i) {
    $kernel->post( 'test', 'dcc', $who, 'send', '/etc/shells' );
  }
}


sub irc_dcc_request {
  my ($kernel, $nick, $type, $port, $magic, $filename, $size) =
    @_[KERNEL, ARG0 .. ARG5];

  print "DCC $type request from $nick on port $port\n";
  $nick = ($nick =~ /^([^!]+)/);
  $nick =~ s/\W//;
  $kernel->post( 'test', 'dcc_accept', $magic, "$1.$filename" );
}


# here's where execution starts.

POE::Component::IRC->new( 'test' ) or
  die "Can't instantiate new IRC component!\n";
POE::Session->create( package_states => [ 'main' => [qw(_start _stop irc_001 irc_kick
				 irc_disconnected irc_error irc_socketerr
				 irc_dcc_done irc_dcc_error irc_dcc_request
				 irc_public)],], );
$poe_kernel->run();

exit 0;
