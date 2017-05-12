#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;
use Number::Phone::NO::Data;
$Number::Phone::NO::Data::DEBUG = 0;

{
    my $bucket = Number::Phone::NO::Data::lookup("98293610");
    ok($bucket->{is_mobile}, "lookup works");
}

{
    my $bucket = Number::Phone::NO::Data::lookup("02224");
    is($bucket->{is_specialrate}, 1, "returns properly for non-existant numbers");
}