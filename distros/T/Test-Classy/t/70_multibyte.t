use strict;
use warnings;
use lib "t/lib", glob("extlib/*/lib");
use Test::Classy;

load_tests_from 'Test::Classy::Test::Multibyte';

Test::More::plan( tests => Test::Classy->plan + 1 );
Test::More::ok( Test::Classy->plan, 'test is recognized' );

run_tests;
