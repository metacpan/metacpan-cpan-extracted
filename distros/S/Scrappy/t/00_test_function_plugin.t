#!/usr/bin/env perl

use FindBin;
use Test::More $ENV{TEST_LIVE} ?
    (tests => 1) : (skip_all => 'env var TEST_LIVE not set, live testing is not enabled');

use_ok 'Scrappy';
