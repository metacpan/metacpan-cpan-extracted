use strict;
use warnings;
use lib './t/lib';
use Test::More;
use Test::SharedFork;
use Qudo;
use Qudo::Test;
use Qudo::Parallel::Manager;
use IO::Socket::INET;

my $test_db = 'palallel_manager';
Qudo::Test::setup_dbs([$test_db]);

my $qudo = Qudo->new(
    databases => [+{
        dsn => "dbi:SQLite:./test_qudo_${test_db}.db",
    }],
);
$qudo->enqueue('Worker::Test', {arg => 'foo'});

my $manager = Qudo::Parallel::Manager->new(
    databases => [+{
        dsn => "dbi:SQLite:./test_qudo_${test_db}.db",
    }],
    manager_abilities  => [qw/Worker::Test/],
    max_spare_workers  => 10,
    max_spare_workersa => 50,
    max_workers        => 50,
    debug => 0,
);

ok $manager;

is $qudo->job_count->{'dbi:SQLite:./test_qudo_palallel_manager.db'}, 1;

my $ppid = $$;

if ( fork ) {
    $manager->run;
    wait;
} else {

    sleep(2);

    my $sock = IO::Socket::INET->new(
        PeerHost => '127.0.0.1',
        PeerPort => 90000,
        Proto    => 'tcp',
    ) or die 'can not connect admin port.';

    my $status = $sock->getline;
    diag($status);
    ok $status;
    $sock->close;

    kill 'TERM', $ppid;
}

is $qudo->job_count->{'dbi:SQLite:./test_qudo_palallel_manager.db'}, 0;

Qudo::Test::teardown_dbs([$test_db]);

done_testing;

