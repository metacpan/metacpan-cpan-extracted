#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 499;
use Test::Exception;
use_ok('Statistics::QMethod::QuasiNormalDist');

for my $i ( 5 .. 500) {
    lives_ok{get_q_dist($i)};
}
dies_ok{get_q_dist(4)};
dies_ok{get_q_dist(501)};
