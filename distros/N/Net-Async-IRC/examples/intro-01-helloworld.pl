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

await $irc->do_PRIVMSG(
   target => $TARGET,
   text   => "Hello, World"
);
