#!/usr/bin/perl

use strict;
use Test::More tests => 5;

my ($class, $l);
BEGIN {
    $class = 'Net::Cisco::AccessList::Extended';
    use_ok($class);
}

eval{ $l = $class->new };
like( $@, qr/^missing parameter for list name/, 'dies with no name' );

eval{ $l = $class->new('TEST_LIST') };
isa_ok( $l, $class, 'new object created' );

can_ok( $l, 'dump' );
is( $l->dump, '', 'dump empty list' );

