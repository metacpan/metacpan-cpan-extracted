package TAP::Formatter::TeamCity::Test::ExitFast;

use strict;
use warnings;

use Test::Class::Moose;

sub test_method_1 {
    exit;
    ## no critic (ControlStructures::ProhibitUnreachableCode)
    ok 1, 'tcm-method-1';
}

1;
