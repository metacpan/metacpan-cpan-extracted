#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 16;

use Pinwheel::Model::DateBase;


# Day correction
{
    my $fn;

    $fn = sub {
        my ($y, $m, $d) = @_;
        return Pinwheel::Model::DateBase::_correct_day($y, $m - 1, $d);
    };

    is(&$fn(1900,  2, 31), 28);
    is(&$fn(1999,  2, 31), 28);
    is(&$fn(2000,  2, 31), 29);
    is(&$fn(2004,  2, 31), 29);

    is(&$fn(2007,  1, 50), 31);
    is(&$fn(2007,  2, 50), 28);
    is(&$fn(2007,  3, 50), 31);
    is(&$fn(2007,  4, 50), 30);
    is(&$fn(2007,  5, 50), 31);
    is(&$fn(2007,  6, 50), 30);
    is(&$fn(2007,  7, 50), 31);
    is(&$fn(2007,  8, 50), 31);
    is(&$fn(2007,  9, 50), 30);
    is(&$fn(2007, 10, 50), 31);
    is(&$fn(2007, 11, 50), 30);
    is(&$fn(2007, 12, 50), 31);
}
