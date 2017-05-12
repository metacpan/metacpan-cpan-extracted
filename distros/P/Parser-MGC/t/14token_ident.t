#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

package TestParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   return $self->token_ident;
}

package main;

my $parser = TestParser->new;

is( $parser->from_string( "foo" ), "foo", 'Identifier' );

is( $parser->from_string( "x" ), "x", 'Single-letter identifier' );

ok( !eval { $parser->from_string( "123" ) }, '"123" fails' );
is( $@,
   qq[Expected ident on line 1 at:\n] .
   qq[123\n] .
   qq[^\n],
   'Exception from "123" failure' );

ok( !eval { $parser->from_string( "some-ident" ) }, '"some-ident" fails on default identifier' );

$parser = TestParser->new(
   patterns => { ident => qr/[[:alpha:]_][\w-]+/ },
);

is( $parser->from_string( "some-ident" ), "some-ident", '"some-ident" passes with new token pattern' );

done_testing;
