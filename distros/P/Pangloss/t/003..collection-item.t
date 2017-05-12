#!/usr/bin/perl

##
## Tests for Pangloss::Collection::Item
##

use blib;
use strict;
use warnings;

use Error qw( :try );
use Test::More 'no_plan';

BEGIN { use_ok("Pangloss::Collection::Item"); }

my $item = new Test::Item;
ok( $item, 'new' ) || die("cannot proceed\n");

{
    my $e;
    try { $item->key } catch Error with { $e = shift };
    ok( $e, 'key' );
}

is( $item->error( 'test' ), $item, 'error(set)' );
is( $item->error, 'test',          'error(get)' );


package Test::Item;
use base qw( Pangloss::Collection::Item );
