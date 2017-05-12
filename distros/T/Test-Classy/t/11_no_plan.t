use strict;
use warnings;
use lib "t/lib", glob("extlib/*/lib");
use Test::Classy;

load_tests_from 'Test::Classy::Test::NoPlan';

run_tests;
