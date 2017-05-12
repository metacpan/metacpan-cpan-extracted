use strict;
use warnings;

use Test::More tests => 1;
use lib 'lib';

# TEST:source "$^CURRENT_DIRNAME/lib/MyMoreTests.pm"
use MyMoreTests;

# TEST
is (5, 5, "Hello");

# TEST*$my_more_tests_number;
my_more_tests();

