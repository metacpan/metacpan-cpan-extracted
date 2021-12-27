#!/usr/bin/perl

use v5.14;
use warnings;

use Future::AsyncAwait 0.47; # toplevel await

use IO::Async::Loop;
use Net::Async::IRC;

my $loop = IO::Async::Loop->new;

my $irc = Net::Async::IRC->new;
$loop->add( $irc );

my $SERVER = "irc.example.net";
my $NICK = "MyNick";
my $TARGET = "TargetNick";

await $irc->login(
   host => $SERVER,
   nick => $NICK,
);

my $target_folded = $irc->casefold_name( $TARGET );

$irc->configure(
   on_message_text => sub {
      my ( undef, $message, $hints ) = @_;
      return unless $hints->{prefix_nick_folded} eq $target_folded;

      print "The user said: $hints->{text}\n";
   },
   on_message_ctcp_ACTION => sub {
      my ( undef, $message, $hints ) = @_;
      return unless $hints->{prefix_nick_folded} eq $target_folded;

      print "The user acted: $hints->{ctcp_args}\n";
   },
);

await $irc->do_PRIVMSG(
   target => $TARGET,
   text   => "Hello, what's your name?"
);

$loop->run;
