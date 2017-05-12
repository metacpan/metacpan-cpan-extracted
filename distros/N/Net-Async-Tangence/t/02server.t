#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::HexString;
use Test::Memory::Cycle;
use Test::Refcount;

use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::OS;
use IO::Async::Stream;

use Tangence::Constants;
use Tangence::Registry;

use lib ".";
use t::Conversation;

use t::TestObj;

unless( VERSION_MAJOR == 0 and VERSION_MINOR == 4 ) {
   plan skip_all => "Tangence version mismatch";
}

use Net::Async::Tangence::Server;
$Tangence::Message::SORT_HASH_KEYS = 1;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $registry = Tangence::Registry->new(
   tanfile => "t/TestObj.tan",
);
my $obj = $registry->construct(
   "t::TestObj",
   scalar   => 123,
   s_scalar => 456,
);

is_oneref( $obj, '$obj has refcount 1 initially' );

my $server = Net::Async::Tangence::Server->new(
   registry => $registry,
);

is_oneref( $server, '$server has refcount 1 initially' );

$loop->add( $server );

is_refcount( $server, 2, '$server has refcount 2 after $loop->add' );

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

my $conn = $server->make_new_connection( $S1 );

is_refcount( $server, 2, '$server has refcount 2 after new BE' );
# Three refs: one in Server, one in IO::Async::Loop, one here
is_refcount( $conn, 3, '$conn has refcount 3 initially' );

# Initialisation
{
   $S2->syswrite( $C2S{INIT} );

   is_hexstr( wait_for_message, $S2C{INITED}, 'serverstream initially contains INITED message' );

   is( $conn->minor_version, 4, '$conn->minor_version after MSG_INIT' );

   $S2->syswrite( $C2S{GETROOT} );

   is_hexstr( wait_for_message, $S2C{GETROOT}, 'serverstream contains root object' );

   # lexical $obj + 2 smashed properties
   is_refcount( $obj, 3, '$obj has refcount 3 after MSG_GETROOT' );

   is( $conn->identity, "testscript", '$conn->identity' );

   $S2->syswrite( $C2S{GETREGISTRY} );

   is_hexstr( wait_for_message, $S2C{GETREGISTRY}, 'serverstream contains registry' );
}

# Methods
{
   $S2->syswrite( $C2S{CALL} );

   is_hexstr( wait_for_message, $S2C{CALL}, 'serverstream after response to CALL' );
}

# That'll do; everything should be tested by Tangence itself

# lexical $obj + 2 smashed properties
is_refcount( $obj, 3, '$obj has refcount 3 before shutdown' );

is_refcount( $server, 2, '$server has refcount 2 before $loop->remove' );

$loop->remove( $server );

is_oneref( $server, '$server has refcount 1 before shutdown' );

{
   no warnings 'redefine';
   local *Tangence::Property::Instance::_forbid_arrayification = sub {};

   memory_cycle_ok( $obj, '$obj has no memory cycles' );
   memory_cycle_ok( $registry, '$registry has no memory cycles' );
   # Can't easily do $server yet because Devel::Cycle will throw
   #   Unhandled type: GLOB at /usr/share/perl5/Devel/Cycle.pm line 107.
   # on account of filehandles
}

$conn->close;
undef $server;

is_oneref( $conn, '$conn has refcount 1 after shutdown' );

done_testing;
