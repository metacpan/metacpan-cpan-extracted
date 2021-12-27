#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::Stream;

use Net::Async::IRC;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";

my $irc = Net::Async::IRC->new(
   handle => $S1,
);
$loop->add( $irc );

# privmsg
{
   my $f = $irc->do_PRIVMSG( target => "#target", text => "Your message here" );

   isa_ok( $f, "Future", '$f' );

   my $serverstream = "";
   wait_for_stream { $serverstream =~ m/(?:.*$CRLF)/ } $S2 => $serverstream;

   is( $serverstream, "PRIVMSG #target :Your message here$CRLF",
      '->privmsg' );

   ok( $f->is_ready, '$f is ready' );
}

done_testing;
