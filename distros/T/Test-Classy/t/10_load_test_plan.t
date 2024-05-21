use strict;
use warnings;
use lib "t/lib", glob("extlib/*/lib");
use Test::Classy;
use Test::More;

load_test 'Test::Classy::Test::Basic::Plain';

ok( Test::Classy->plan == 6 );

done_testing;