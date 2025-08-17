#!/usr/bin/perl -w

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use constant TESTS => [
    [[qw(           )] => 0],
    [[qw(xxx        )] => 3],
    [[qw(xxx xxx    )] => 3],
    [[qw(xxx xxz    )] => 4],
    [[qw(xxx zzz    )] => 6],
    [[qw(xxx zzz xyz)] => 7],
    [[qw(xxx zzz Xyz)] => 8],
    [[qw(xxx zzz XyZ)] => 9],
];

use Test::More tests => (1 + scalar(@{TESTS()})*3);

use_ok('String::Super');

foreach my $test (@{TESTS()}) {
    my ($blobs, $optimum) = @{$test};
    my $super = String::Super->new;

    isa_ok($super, 'String::Super');

    is($super->add_blob(@{$blobs}), 0);

    is(length($super->result), $optimum, 'found best length');
}

exit 0;

