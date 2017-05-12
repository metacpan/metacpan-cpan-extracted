use strict;
use warnings;
use Test::More;
use Scalar::Util qw'reftype';
use Data::Dumper;

BEGIN {
    use_ok("Net::Hadoop::YARN::HistoryServer");
}

SKIP: {
    skip "No YARN_HISTORY_SERVER in environment", 1 if !$ENV{YARN_HISTORY_SERVER};

    my $hist;
    isa_ok( $hist = Net::Hadoop::YARN::HistoryServer->new(
                servers => [ split /,/, $ENV{YARN_HISTORY_SERVER} ]
            ),
            "Net::Hadoop::YARN::HistoryServer"
    );

    my ($jobs, $job);
    is( reftype( $jobs = $hist->jobs( { limit => 10 } ) ), "ARRAY", "array of jobs" );
    my $job_id;
    like( $job_id = $jobs->[0]->{id}, qr/^job/, "job ID found" );
    is( reftype( $job = $hist->job($job_id) ), "HASH", "single job is a hash" );
    is( $job->{id}, $job_id, "job IDs match for job() and jobs->[0]{id}" );

    ok( length $hist->jobcounters($job_id)->[0]{counterGroupName} > 0,
            'at least 1 counterGroupName in jobcounters' );
    is( reftype( $hist->jobconf($job_id)->{property} ), 'ARRAY', 'array of config properties' );

    ok( $hist->jobattempts($job_id)->[0]{id} > 0, 'jobattempts has at least 1 attempt' );

    my ( $tasks, $task, $task2 );
    is( reftype( $tasks = $hist->tasks($job_id) ), "ARRAY", 'array of tasks' );
    is( reftype( $task  = $tasks->[0] ),           "HASH",  'task is a hash' );
    $task2 = $hist->task( $job_id, $task->{id} );
    is_deeply( $task2, $task, 'task and tasks[0] are the same' );

    ok( length $hist->taskcounters( $job_id, $task->{id} )->[0]{counterGroupName} > 0,
            'at least 1 counterGroupName in taskcounters' );

    my ( $task_attempts, $task_attempt, $task_attempt2 );
    is( reftype( $task_attempts = $hist->taskattempts( $job_id, $task->{id} ) ),
            "ARRAY", 'array of tasks attempts' );
    is( reftype( $task_attempt = $task_attempts->[0] ), "HASH", 'task attempt is a hash' );
    $task_attempt2 = $hist->taskattempt( $job_id, $task->{id}, $task_attempt->{id} );
    is_deeply( $task_attempt, $task_attempt2, 'taskattempt and taskattempts[0] are the same' );

    ok(     length $hist->taskattemptcounters( $job_id, $task->{id}, $task_attempt->{id} )
                ->[0]{counterGroupName} > 0,
            'at least 1 counterGroupName in taskattemptcounters'
    );

}

done_testing();
