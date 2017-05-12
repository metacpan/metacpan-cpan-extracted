use strict;
use warnings;
use Test::More;
use Scalar::Util qw'reftype';
use Data::Dumper;

BEGIN {
    use_ok("Net::Hadoop::YARN::ApplicationMaster");
}

SKIP: {
    skip "No YARN_RESOURCE_MANAGER in environment", 1 if !$ENV{YARN_RESOURCE_MANAGER};

    use Net::Hadoop::YARN::ResourceManager;
    my $rm
        = Net::Hadoop::YARN::ResourceManager->new( servers => [ split /,/, $ENV{YARN_RESOURCE_MANAGER} ] );

    my $sample_apps = $rm->apps( { limit => 100, states => "RUNNING" } );

    fail("No running applications in $ENV{YARN_RESOURCE_MANAGER}!") if ! @{ $sample_apps };

    # Just ignore sparkies until we have a workaround or solution.
    #
    my $sparky;
    my ($app) = map { ($_->{applicationType} || '') eq 'SPARK' ? do { $sparky++; () } : $_ } @{ $sample_apps };

    note( sprintf "Collected %s spark apps and ignoring all of them.", $sparky || 'none');

    my $type = $app ? $app->{applicationType} || '' : '';

    if ( ! $app || $type eq 'SPARK' ) {
        # A relevant discussion:
        # http://stackoverflow.com/questions/30070276/json-not-returned-from-yarn-rest-api
        todo_skip("Spark applications do not return valida data. Skipping");
    }

    my $app_id = $app->{id};
    my $am;
    isa_ok(
        $am = Net::Hadoop::YARN::ApplicationMaster->new(
            servers => [ split /,/, $ENV{YARN_RESOURCE_MANAGER} ]
        ),
        "Net::Hadoop::YARN::ApplicationMaster"
    );

    my ( $jobs, $job );
    is( reftype( $jobs = $am->jobs( $app_id, { limit => 10 } ) ), "ARRAY", "array of jobs" );

    #print Dumper $jobs;
    my $job_id;
    like( $job_id = $jobs->[0]->{id}, qr/^job/, "job ID found" );
    is( reftype( $job = $am->job( $app_id, $job_id ) ), "HASH", "single job is a hash" );
    is( $job->{id}, $job_id, "job IDs match for job() and jobs->[0]{id}" );

    ok( length $am->jobcounters( $app_id, $job_id )->[0]{counterGroupName} > 0,
        'at least 1 counterGroupName in jobcounters' );
    is( reftype( $am->jobconf( $app_id, $job_id )->{property} ),
        'ARRAY', 'array of config properties' );

    ok( $am->jobattempts( $app_id, $job_id )->[0]{id} > 0,
        'jobattempts has at least 1 attempt' );

    my ( $tasks, $task, $task2 );
    is( reftype( $tasks = $am->tasks( $app_id, $job_id ) ), "ARRAY", 'array of tasks' );
    is( reftype( $task = $tasks->[0] ), "HASH", 'task is a hash' );
    $task2 = $am->task( $app_id, $job_id, $task->{id} );

    # cannot compare both because the gets are not atomic (the elapsed time changes between the 2 objects for instance, as it's in milliseconds)
    is_deeply(
        [ @{$task2}{qw(id startTime)} ],
        [ @{$task}{qw(id startTime)}  ],
        'task and tasks[0] are the same'
    );

    #    print Dumper [ $task, $task2 ];

    ok( length $am->taskcounters( $app_id, $job_id, $task->{id} )->[0]{counterGroupName} > 0,
        'at least 1 counterGroupName in taskcounters' );

    my ( $task_attempts, $task_attempt, $task_attempt2 );
    is( reftype( $task_attempts = $am->taskattempts( $app_id, $job_id, $task->{id} ) ),
        "ARRAY", 'array of tasks attempts' );
    is( reftype( $task_attempt = $task_attempts->[0] ), "HASH", 'task attempt is a hash' );
    $task_attempt2 = $am->taskattempt( $app_id, $job_id, $task->{id}, $task_attempt->{id} );
    is_deeply(
        [ @{$task_attempt2}{qw(id startTime assignedContainerId)} ],
        [ @{$task_attempt}{qw(id startTime assignedContainerId)} ],
        'attempt and attempts[0] are the same'
    );

    ok( length $am->taskattemptcounters( $app_id, $job_id, $task->{id}, $task_attempt->{id} )
            ->[0]{counterGroupName} > 0,
        'at least 1 counterGroupName in taskattemptcounters'
    );

}

done_testing();
