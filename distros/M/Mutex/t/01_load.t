#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Mutex');
    use_ok('Mutex::Util');
    use_ok('Mutex::Flock');
    use_ok('Mutex::Channel');
}

done_testing;

