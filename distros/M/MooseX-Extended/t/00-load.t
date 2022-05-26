#!/usr/bin/env perl

use lib 'lib';
use Test::Most;

use MooseX::Extended        ();
use MooseX::Extended::Types ();
use MooseX::Extended::Role  ();

pass "We were able to lood our primary modules";

diag "Testing MooseX::Extended $MooseX::Extended::VERSION, Perl $], $^X";

done_testing;
