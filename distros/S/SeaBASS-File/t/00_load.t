#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('SeaBASS::File', qw(STRICT_READ STRICT_WRITE STRICT_ALL INSERT_BEGINNING INSERT_END));
}

done_testing();
