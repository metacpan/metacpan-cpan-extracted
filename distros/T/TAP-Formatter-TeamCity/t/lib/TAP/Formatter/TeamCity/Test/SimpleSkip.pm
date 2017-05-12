package TAP::Formatter::TeamCity::Test::SimpleSkip;

use strict;
use warnings;

use Test::Class::Moose;

sub test_setup {
    my ( $test, $report ) = @_;
    if ( 'test_method_1' eq $report->name ) {
        $test->test_skip('"the reason for skipping test_method_1"');
    }
}

sub test_method_1 {
    ok 1, 'tcm-method-1-test-1';
}

sub test_method_2 {
    ok 1, 'tcm-method-2-test-1';
}

1;
