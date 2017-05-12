#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::HexString;
use Test::Identity;
use Test::Refcount;

use Tangence::Constants;
use Tangence::Registry;

use Tangence::Server;
$Tangence::Message::SORT_HASH_KEYS = 1;

use lib ".";
use t::Conversation;
use t::TestObj;

my $registry = Tangence::Registry->new(
   tanfile => "t/TestObj.tan",
);
my $obj = $registry->construct(
   "t::TestObj",
   scalar   => 123,
   s_scalar => 456,
);

is_oneref( $obj, '$obj has refcount 1 initially' );

my $server = TestServer->new();
$server->registry( $registry );

is_oneref( $server, '$server has refcount 1 initially' );

# Initialisation
{
   $server->send_message( $C2S{INIT} );

   is_hexstr( $server->recv_message, $S2C{INITED}, 'serverstream initially contains INITED message' );

   is( $server->minor_version, 4, '$server->minor_version after MSG_INIT' );

   $server->send_message( $C2S{GETROOT} );

   is_hexstr( $server->recv_message, $S2C{GETROOT}, 'serverstream contains root object' );

   # One here, one in each of two smashed prop watches
   is_refcount( $obj, 3, '$obj has refcount 3 after MSG_GETROOT' );

   is( $server->identity, "testscript", '$server->identity' );

   $server->send_message( $C2S{GETREGISTRY} );

   is_hexstr( $server->recv_message, $S2C{GETREGISTRY}, 'serverstream contains registry' );
}

# Methods
{
   $server->send_message( $C2S{CALL} );

   is_hexstr( $server->recv_message, $S2C{CALL}, 'serverstream after response to CALL' );

   $server->send_message( $C2S{CALL_NORETURN} );

   is_hexstr( $server->recv_message, $S2C{CALL_NORETURN}, 'serverstream after respones to void-returning CALL' );
}

# Events
{
   $server->send_message( $C2S{SUBSCRIBE} );

   is_hexstr( $server->recv_message, $S2C{SUBSCRIBED}, 'received MSG_SUBSCRIBED response' );

   $obj->fire_event( event => 20, "bye" );

   is_hexstr( $server->recv_message, $S2C{EVENT}, 'received MSG_EVENT' );

   $server->send_message( $MSG_OK );

   $server->send_message( $C2S{UNSUBSCRIBE} );

   is_hexstr( $server->recv_message, $MSG_OK, 'received MSG_OK response to MSG_UNSUBSCRIBE' );
}

# Properties get/set
{
   $server->send_message( $C2S{GETPROP} );

   is_hexstr( $server->recv_message, $S2C{GETPROP_123}, 'received property value after MSG_GETPROP' );

   $server->send_message( $C2S{GETPROPELEM_HASH} );

   is_hexstr( $server->recv_message, $S2C{GETPROPELEM_HASH}, 'received element of hash property after MSG_GETPROPELEM' );

   $server->send_message( $C2S{GETPROPELEM_ARRAY} );

   is_hexstr( $server->recv_message, $S2C{GETPROPELEM_ARRAY}, 'received element of array property after MSG_GETPROPELEM' );

   $server->send_message( $C2S{SETPROP} );

   is_hexstr( $server->recv_message, $MSG_OK, 'received OK after MSG_SETPROP' );

   is( $obj->get_prop_scalar, 135, '$obj->get_prop_scalar after set_property' );
}

# Properties watch
{
   $server->send_message( $C2S{WATCH} );

   is_hexstr( $server->recv_message, $S2C{WATCHING}, 'received MSG_WATCHING response' );

   $obj->set_prop_scalar( 147 );

   is_hexstr( $server->recv_message, $S2C{UPDATE_SCALAR_147}, 'received property MSG_UPDATE notice' );

   $server->send_message( $MSG_OK );

   $server->send_message( $C2S{UNWATCH} );

   is_hexstr( $server->recv_message, $MSG_OK, 'received MSG_OK to MSG_UNWATCH' );
}

# Cursors
{
   $server->send_message( $C2S{WATCH_ITER} );

   is_hexstr( $server->recv_message, $S2C{WATCHING_ITER}, 'received MSG_WATCHING_ITER response' );

   $server->send_message( $C2S{ITER_NEXT_1} );

   is_hexstr( $server->recv_message, $S2C{ITER_NEXT_1}, 'result from MSG_ITER_NEXT 1 forward' );

   $server->send_message( $C2S{ITER_NEXT_5} );

   is_hexstr( $server->recv_message, $S2C{ITER_NEXT_5}, 'result from MSG_ITER_NEXT 5 forward' );

   $server->send_message( $C2S{ITER_NEXT_BACK} );

   is_hexstr( $server->recv_message, $S2C{ITER_NEXT_BACK}, 'result from MSG_ITER_NEXT 1 backward' );

   $server->send_message( $C2S{ITER_DESTROY} );

   is_hexstr( $server->recv_message, $MSG_OK, 'received OK to MSG_ITER_DESTROY' );
}

# Test object destruction
{
   my $obj_destroyed = 0;

   $obj->destroy( on_destroyed => sub { $obj_destroyed = 1 } );

   is_hexstr( $server->recv_message, $S2C{DESTROY}, 'MSG_DESTROY from server' );

   $server->send_message( $MSG_OK );

   is( $obj_destroyed, 1, 'object gets destroyed' );
}

is_oneref( $server, '$server has refcount 1 before shutdown' );
undef $server;

is_oneref( $obj, '$obj has refcount 1 before shutdown' );
is_oneref( $registry, '$registry has refcount 1 before shutdown' );

done_testing;

package TestServer;

use strict;
use base qw( Tangence::Server );

sub new
{
   return bless { written => "" }, shift;
}

sub tangence_write
{
   my $self = shift;
   $self->{written} .= $_[0];
}

sub send_message
{
   my $self = shift;
   my ( $message ) = @_;
   $self->tangence_readfrom( $message );
   length($message) == 0 or die "Server failed to read the whole message";
}

sub recv_message
{
   my $self = shift;
   my $message = $self->{written};
   $self->{written} = "";
   return $message;
}
