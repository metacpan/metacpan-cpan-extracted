#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;

use Pinwheel::Helpers::DateTime qw(now hh_mm format_time);
use Pinwheel::Model::Time;


# Now
{
    my ($t1, $t2, $now);

    $t1 = time();
    $now = now();
    $t2 = time();
    cmp_ok($t1, '<=', $now->timestamp);
    cmp_ok($t2, '>=', $now->timestamp);
    is($now, $now->getlocal);
}


# Time formatting
{
    my ($t);

    $t = Pinwheel::Model::Time::local(2008, 1, 2, 12, 30, 45);
    is(hh_mm($t), '12:30');
    is(format_time('%Y-%m-%d %H:%M:%S', $t), '2008-01-02 12:30:45');
}
