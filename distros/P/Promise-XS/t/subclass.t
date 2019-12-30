#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Promise::XS;

{
    package SomePromise;

    our @ISA = ('Promise::XS::Promise');
}

my $def = Promise::XS::deferred();

my $promise = $def->promise();
bless $promise, 'SomePromise';

for my $fn ( qw( then catch finally ) ) {
    my $p2 = $promise->$fn( sub {} );
    isa_ok( $p2, 'SomePromise', "$fn() honors subclass" ) or diag ref $p2;
}

done_testing;

1;
