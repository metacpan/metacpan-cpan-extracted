#!/usr/bin/env perl

use Scrappy;
use FindBin;
use Test::More $ENV{TEST_LIVE} ?
    (tests => 3) : (skip_all => 'env var TEST_LIVE not set, live testing is not enabled');


my  $s = Scrappy->new;
ok  1 == $s->debug;
ok  0 == $s->debug(0);
ok  1 == $s->debug(1);

