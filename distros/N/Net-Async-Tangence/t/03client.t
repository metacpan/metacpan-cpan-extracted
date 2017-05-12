#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal qw( dies_ok );
use Test::HexString;
use Test::Memory::Cycle;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::OS;

use Tangence::Constants;
use Tangence::Registry;

use lib ".";
use t::Conversation;

use Net::Async::Tangence::Client;
$Tangence::Message::SORT_HASH_KEYS = 1;

unless( VERSION_MAJOR == 0 and VERSION_MINOR == 4 ) {
   plan skip_all => "Tangence version mismatch";
}

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";

{
   my $clientstream = "";
   sub wait_for_message
   {
      my $msglen;
      wait_for_stream { length $clientstream >= 5 and
                        length $clientstream >= ( $msglen = 5 + unpack "xN", $clientstream ) } $S2 => $clientstream;

      return substr( $clientstream, 0, $msglen, "" );
   }
}

my $client = Net::Async::Tangence::Client->new(
   handle => $S1,
   on_error => sub { die "Test died early - $_[0]" },
   identity => "testscript",
);
$loop->add( $client );

# Initialisation
{
   is_hexstr( wait_for_message, $C2S{INIT}, 'client stream initially contains MSG_INIT' );

   $S2->syswrite( $S2C{INITED} );

   is_hexstr( wait_for_message, $C2S{GETROOT}, 'client stream contains MSG_GETROOT' );

   $S2->syswrite( $S2C{GETROOT} );

   wait_for { defined $client->rootobj };

   is_hexstr( wait_for_message, $C2S{GETREGISTRY}, 'client stream contains MSG_GETREGISTRY' );

   $S2->syswrite( $S2C{GETREGISTRY} );

   wait_for { defined $client->registry };
}

my $objproxy = $client->rootobj;

# Methods
{
   my $f = $objproxy->call_method(
      method => 10, "hello",
   );

   is_hexstr( wait_for_message, $C2S{CALL}, 'client stream contains MSG_CALL' );

   $S2->syswrite( $S2C{CALL} );

   wait_for { $f->is_ready };

   is( scalar $f->get, "10/hello", 'result of call_method()' );
}

# That'll do; everything should be tested by Tangence itself

memory_cycle_ok( $objproxy, '$objproxy has no memory cycles' );

# Deconfigure the clientection otherwise Devel::Cycle will throw
#   Unhandled type: GLOB at /usr/share/perl5/Devel/Cycle.pm line 107.
# on account of filehandles
$client->configure( handle => undef );
memory_cycle_ok( $client, '$client has no memory cycles' );

done_testing;
