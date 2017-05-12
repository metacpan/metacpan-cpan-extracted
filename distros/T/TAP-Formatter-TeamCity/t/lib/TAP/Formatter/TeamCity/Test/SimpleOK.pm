package TAP::Formatter::TeamCity::Test::SimpleOK;

use strict;
use warnings;

use Test::Class::Moose;

sub test_method_1 {
    ok 1, 'tcm-method-1-test-1';
    ok 1, 'tcm-method-1-test-2';
}

sub test_method_2 {
    ok 1, 'tcm-method-2-test-1';
    ok 1, 'tcm-method-2-test-2';
}

1;
