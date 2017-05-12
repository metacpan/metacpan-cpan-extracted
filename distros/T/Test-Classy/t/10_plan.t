use strict;
use warnings;
use lib "t/lib", glob("extlib/*/lib");
use Test::Classy;
use Test::More;

plan tests => 2;

load_tests_from 'Test::Classy::Test::Basic';

ok( Test::Classy->plan == 34 );

Test::Classy->reset; # remove all the previous tests

load_test 'Test::Classy::Test::Basic::Plain';

ok( Test::Classy->plan == 6 );
