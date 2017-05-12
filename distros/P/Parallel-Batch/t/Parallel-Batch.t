# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Parallel-Batch.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('Parallel::Batch') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sub test_file {
    open my $test, '>', "test_$_[0]";
    close $test;
}

my $batch = Parallel::Batch->new({code => \&test_file, jobs => [(1..10)], maxprocs => 4});

$batch->run();

for (1..10)
{
    ok(-f "test_$_");
    unlink "test_$_";
}
