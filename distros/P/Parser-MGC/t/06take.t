#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

package TestParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   # Some gut-wrenching to make the test pass
   [ $self->take( 5 ), $self->take( 5 ), $self->take( length( $self->{str} ) - pos( $self->{str} ) ) ]
}

package main;

my $parser = TestParser->new;

is_deeply( $parser->from_string( "Hello There" ),
   [ "Hello", " Ther", "e" ],
   '"Hello There"' );

done_testing;
