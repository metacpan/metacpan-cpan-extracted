#!/usr/bin/env perl
use strict;
use warnings;

use PHP::Serialization;
use Test::More tests => 2;

my $a = {'020' => '001'};
my $str = PHP::Serialization::serialize( $a );
is($str,'a:1:{s:3:"020";s:3:"001";}', 'Keys and vals are string for 0 prefixed numbers');

my $b = {'0' => '0'};
$str = PHP::Serialization::serialize( $b );
is($str,'a:1:{i:0;i:0;}', 'Keys and vals are ints for 0');

