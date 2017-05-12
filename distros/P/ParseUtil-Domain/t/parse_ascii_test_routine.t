#!/usr/bin/env perl


use lib qw{ ./t/lib };

use Test::More;
use Test::Routine::Util;

run_tests(
    'Test toggle between puny-encoded ascii and unicode',
    ['AsciiToggle','ToggleTester']
);

run_tests(
    'Test toggle between unicode and puny-encoded ascii',
    ['UnicodeToggle','ToggleTester']
);

done_testing;
