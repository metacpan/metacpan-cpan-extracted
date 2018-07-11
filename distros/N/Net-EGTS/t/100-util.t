#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 6;

BEGIN {
    use_ok 'Net::EGTS::Util';
}

subtest 'usize' => sub {
    plan tests => 5;

    is usize('C'), 1, 'C';
    is usize('S'), 2, 'S';
    is usize('L'), 4, 'L';

    is usize('B8'), 1, 'B8';

    is usize('CS'), 3, 'CS';
};

subtest 'lat2mod' => sub {
    plan tests => 1;

    is lat2mod(55.767856), 2661345751, 'lat 1';
};

subtest 'lon2mod' => sub {
    plan tests => 1;

    is lon2mod(37.672935), 898911242, 'lon 1';
};

subtest 'mod2lat' => sub {
    plan tests => 2;

    is sprintf('%.6f', mod2lat(2661345751, 0)),   55.767856, 'lat unsigned';
    is sprintf('%.6f', mod2lat(2661345751, 1)), - 55.767856, 'lat signed';
};

subtest 'mod2lon' => sub {
    plan tests => 2;

    is sprintf('%.6f', mod2lon(898911242, 0)),   37.672935, 'lon unsigned';
    is sprintf('%.6f', mod2lon(898911242, 1)), - 37.672935, 'lon signed';
};
