#!/usr/bin/perl

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 4;

use_ok('Parcel::Track');
use_ok('Parcel::Track::Role::Base');
use_ok('Parcel::Track::Test');
use_ok('Parcel::Track::KR::Test');
