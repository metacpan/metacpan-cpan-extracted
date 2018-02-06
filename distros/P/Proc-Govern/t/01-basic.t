#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Proc::Govern qw(govern_process);

subtest "basic" => sub {
    plan "skip_all" => "no /bin/bash available" unless -x "/bin/bash";
    my $exit = govern_process(
        command => ["/bin/bash", '-c', 'echo hi'],
    );
    ok($exit == 0);
};

DONE_TESTING:
done_testing;
