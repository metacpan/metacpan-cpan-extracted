#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

my $die;

package TestParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   $self->maybe( sub {
      die $die if $die;
      $self->token_ident;
   } ) ||
      $self->token_int;
}

package TestParser2;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;
   $self->maybe( 'token_ident' ) || $self->token_int;
}

package main;

my $parser = TestParser->new;

is( $parser->from_string( "hello" ), "hello", '"hello"' );
is( $parser->from_string( "123" ), 123, '"123"' );

$die = "Now have to fail\n";
ok( !eval { $parser->from_string( "456" ) }, '"456" with $die fails' );
is( $@, "Now have to fail\n", 'Exception from failure' );

is( TestParser2->new->from_string( "hello" ), "hello", '"hello" as method name' );

done_testing;
