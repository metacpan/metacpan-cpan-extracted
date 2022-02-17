#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Fatal;

package TestParser {
   use base qw( Parser::MGC );

   sub parse_hello
   {
      my $self = shift;

      [ $self->expect( "hello" ), $self->expect( qr/world/ ) ];
   }

   sub parse_hex
   {
      my $self = shift;

      return hex +( $self->expect( qr/0x([0-9A-F]+)/i ) )[1];
   }

   sub parse_foo_or_bar
   {
      my $self = shift;

      return $self->maybe_expect( qr/foo/i ) ||
             $self->maybe_expect( qr/bar/i );
   }

   sub parse_numrange
   {
      my $self = shift;

      return [ ( $self->maybe_expect( qr/(\d+)(?:-(\d+))?/ ) )[1,2] ];
   }
}

my $parser = TestParser->new( toplevel => "parse_hello" );

is_deeply( $parser->from_string( "hello world" ),
   [ "hello", "world" ],
   '"hello world"' );

is_deeply( $parser->from_string( "  hello world  " ),
   [ "hello", "world" ],
   '"  hello world  "' );

is( exception { $parser->from_string( "goodbye world" ) },
   qq[Expected (?^u:hello) on line 1 at:\n] . 
   qq[goodbye world\n] . 
   qq[^\n],
   'Exception from "goodbye world" failure' );

$parser = TestParser->new( toplevel => "parse_hex" );

is( $parser->from_string( "0x123" ), 0x123, "Hex parser captures substring" );

$parser = TestParser->new( toplevel => "parse_foo_or_bar" );

is( $parser->from_string( "Foo" ), "Foo", "FooBar parser first case" );
is( $parser->from_string( "Bar" ), "Bar", "FooBar parser first case" );

$parser = TestParser->new( toplevel => "parse_numrange" );

is_deeply( $parser->from_string( "123-456" ), [ 123, 456 ], "Number range parser complete" );

{
   my $warnings = "";
   local $SIG{__WARN__} = sub { $warnings .= join "", @_ };

   is_deeply( $parser->from_string( "789" ), [ 789, undef ],   "Number range parser lacking max" );
   is( $warnings, "", "Number range lacking max yields no warnings" );
}

done_testing;
