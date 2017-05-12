#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Time::HiRes qw(); # Empty import, just there to let IO::Async and Net::Async::IRC use it

use IO::Async::Test;
use IO::Async::OS;
use IO::Async::Loop;
use IO::Async::Stream;

use Net::Async::IRC;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";

my $lag;
my $pingout;

my $irc = Net::Async::IRC->new(
   handle => $S1,
   on_message => sub { "IGNORE" },

   pingtime => 2,
   pongtime => 1,

   on_pong_reply   => sub { $lag = $_[1] },
   on_ping_timeout => sub { $pingout = 1 },
);

$loop->add( $irc );

# This is all tricky timing-related code. Pay attention

# First [the server] will send three messages, separated by 1sec, and assert
# that the client didn't send a PING

my $serverstream = "";

my $msgcount = 0;

sub tick {
   $msgcount++;
   $S2->syswrite( "HELLO client$CRLF" );

   $loop->enqueue_timer(
      delay => 1,
      code => \&tick
   ) if $msgcount < 3;
}

tick();

wait_for_stream { $msgcount == 3 } $S2 => $serverstream;

is( $serverstream, "", 'client quiet after server noise' );

# Now [the server] will be quiet and assert that the client sends a PING

wait_for_stream { $serverstream =~ m/$CRLF/ } $S2 => $serverstream;

like( $serverstream, qr/^PING .*$CRLF$/, 'client sent PING after server idle' );

# Now lets be a good server and reply to the PING
my ( $pingarg ) = $serverstream =~ m/^PING (.*)$CRLF$/;
$S2->syswrite( ":irc.example.com PONG $pingarg$CRLF" );

undef $lag;
wait_for { defined $lag };

ok( $lag >= 0 && $lag <= 1, 'client acknowledges PONG reply' );

# Now [the server] won't reply to a PING at all, and hope for an event to note
# that it failed

wait_for { defined $pingout };
ok( $pingout, 'client reports PING timeout' );

done_testing;
