#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::HexString;

use Future;

{
   package TestBase;
   use base qw( Protocol::Gearman );

   sub new { bless {}, shift }
}

my $base = TestBase->new;

ok( defined $base, '$base defined' );

# send
{
   my $sent = "";
   no warnings 'once';
   local *TestBase::send = sub {
      shift;
      $sent .= $_[0];
   };

   $base->send_packet( SUBMIT_JOB => "func", "id", "ARGS" );

   is_hexstr( $sent, "\0REQ\x00\x00\x00\x07\x00\x00\x00\x0c" .
         "func\0id\0ARGS",
      'data written by ->pack_send_packet' );
}

# recv
{
   my $buffer = "\0RES\x00\x00\x00\x08\x00\x00\x00\x04ABCDT";

   my $new_handle;

   no warnings 'once';
   local *TestBase::on_JOB_CREATED = sub {
      shift;
      ( $new_handle ) = @_;
   };

   $base->on_recv( $buffer );

   is( $buffer, "T", 'on_recv consumes data, leaves tail' );
   is( $new_handle, "ABCD", '$new_handle set after ->on_recv' );

   $buffer = "\0RES\x00\x00\x00\x13\x00\x00\x00\x15fail\0This call failed";

   like( exception { $base->on_recv( $buffer ) },
      qr/"This call failed"/, 'automatic ERROR packet handling' );
}

# echo_request
{
   no warnings 'once';
   local *TestBase::new_future = sub {
      return Future->new;
   };
   local *TestBase::send_packet = sub {
      my $self = shift;
      my ( $type, @args ) = @_;

      is( $type,    "ECHO_REQ", '$type for sent packet by ->echo_request' );
      is( $args[0], "payload",  '$args[0] for sent packet by ->echo_request' );

      $self->on_ECHO_RES( $args[0] );
   };

   my $payload = $base->echo_request( "payload" )->get;

   is( $payload, "payload", '->echo_request->get yields payload' );
}

done_testing;
