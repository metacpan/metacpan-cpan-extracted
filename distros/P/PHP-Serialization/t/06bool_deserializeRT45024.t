#!/usr/bin/env perl
use strict;
use warnings;

use PHP::Serialization;
use Test::More tests => 2;

my $s = 'b:0;';
my $u = PHP::Serialization::unserialize($s);
is($u, undef, 'b:0 equals undef');

$s = 'a:4:{i:0;s:3:"ABC";i:1;s:3:"OPQ";i:2;s:3:"XYZ";i:3;b:0;}';
$u = PHP::Serialization::unserialize($s);

is_deeply $u, [
    'ABC',
    'OPQ',
    'XYZ',
    undef,
];

