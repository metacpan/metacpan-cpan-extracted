package testlib::Master;
use strict;
use warnings;
use Test::More;

my @TEST_MODULES;

BEGIN {
    @TEST_MODULES = qw(Echo Cycle Error Responder Handlers CustomServer);
    foreach my $test_module (@TEST_MODULES) {
        require "testlib/$test_module.pm";
    }
}

sub run_tests {
    my ($server_runner) = @_;
    foreach my $subtest (@TEST_MODULES) {
        subtest $subtest, sub {
            no strict "refs";
            &{"testlib::${subtest}::run_tests"}($server_runner);
            done_testing;
        };
    }
}

1;
