#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

package TestParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   $self->expect( "hello" );
   $self->expect( qr/world/ );

   return 1;
}

package main;

my $parser = TestParser->new;

ok( $parser->from_string( "hello world" ), '"hello world"' );
ok( $parser->from_string( "hello\nworld" ), '"hello\nworld"' );
ok( !eval { $parser->from_string( "hello\n# Comment\nworld" ) }, '"hello world" with comment fails' );

$parser = TestParser->new(
   patterns => { comment => qr/#.*\n/ },
);

ok( $parser->from_string( "hello\n# Comment\nworld" ), '"hello world" with comment passes' );

done_testing;
