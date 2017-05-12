#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

package TestParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   [ $self->substring_before( "!" ), $self->expect( "!" ) ];
}

package main;

my $parser = TestParser->new;

is_deeply( $parser->from_string( "Hello, world!" ),
   [ "Hello, world", "!" ],
   '"Hello, world!"' );

is_deeply( $parser->from_string( "!" ),
   [ "", "!" ],
   '"Hello, world!"' );

done_testing;
