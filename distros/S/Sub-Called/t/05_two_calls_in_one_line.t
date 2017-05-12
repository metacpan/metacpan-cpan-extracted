#!perl -T

use strict;
use warnings;
use Sub::Called;
use Test::More tests => 2;

sub dummy {
    ok( Sub::Called::with_ampersand() );
}

sub foo {
    ok( ! Sub::Called::with_ampersand() );
}

my %hash = (
    dummy => &dummy,
    foo   => foo(),
);
