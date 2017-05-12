#!/usr/bin/perl

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 1;
use Parcel::Track;

# In detecting these drivers, they should NOT be loaded
ok(
    !defined $Parcel::Track::Test::VERSION,
    'Did not load drivers when locating them'
);
