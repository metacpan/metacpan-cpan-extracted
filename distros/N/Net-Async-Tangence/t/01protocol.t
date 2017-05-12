#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::HexString;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::OS;
use IO::Async::Stream;

use Tangence::Constants;

unless( VERSION_MAJOR == 0 and VERSION_MINOR == 4 ) {
   plan skip_all => "Tangence version mismatch";
}

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";

{
   my $serverstream = "";
   sub wait_for_message
   {
      my $msglen;
      wait_for_stream { length $serverstream >= 5 and
                        length $serverstream >= ( $msglen = 5 + unpack "xN", $serverstream ) } $S2 => $serverstream;

      return substr( $serverstream, 0, $msglen, "" );
   }
}

my @calls;
my $stream = Testing::Protocol->new(
   handle => $S1,
);

ok( defined $stream, 'defined $stream' );
isa_ok( $stream, "Net::Async::Tangence::Protocol", '$stream isa Net::Async::Tangence::Protocol' );

$loop->add( $stream );

$stream->minor_version( 3 );

my $message;

$message = Tangence::Message->new( $stream, MSG_CALL );
$message->pack_int( 1 );
$message->pack_str( "method" );

my $response;
$stream->request(
   request => $message,
   on_response => sub { $response = $_[0] },
);

my $expect;
$expect = "\1" . "\0\0\0\x09" .
          "\x02" . "\x01" .
          "\x26" . "method";

is_hexstr( wait_for_message, $expect, 'serverstream after initial MSG_CALL' );

$S2->syswrite( "\x82" . "\0\0\0\x09" .
               "\x28" . "response" );

wait_for { defined $response };

is( $response->code, MSG_RESULT, '$response->code to initial call' );
is( $response->unpack_str, "response", '$response->unpack_str to initial call' );

$S2->syswrite( "\x04" . "\0\0\0\x08" .
               "\x02" . "\x01" .
               "\x25" . "event" );

wait_for { @calls };

my $c = shift @calls;

is( $c->[2]->unpack_int, 1, '$message->unpack_int after MSG_EVENT' );
is( $c->[2]->unpack_str, "event", '$message->unpack_str after MSG_EVENT' );

$message = Tangence::Message->new( $stream, MSG_OK );
$c->[0]->respond( $c->[1], $message );

$expect = "\x80" . "\0\0\0\0";

is_hexstr( wait_for_message, $expect, '$serverstream after response' );

done_testing;

package Testing::Protocol;

use strict;
use base qw( Net::Async::Tangence::Protocol );

sub handle_request_EVENT
{
   my $self = shift;
   my ( $token, $message ) = @_;

   push @calls, [ $self, $token, $message ];
   return 1;
}
