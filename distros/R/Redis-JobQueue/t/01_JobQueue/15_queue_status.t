#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

use lib 'lib', 't/tlib';

use Test::More;
plan "no_plan";

BEGIN {
    eval "use Test::Exception";                 ## no critic
    plan skip_all => "because Test::Exception required for testing" if $@;
}

BEGIN {
    eval "use Test::RedisServer";               ## no critic
    plan skip_all => "because Test::RedisServer required for testing" if $@;
}

BEGIN {
    eval "use Net::EmptyPort";                  ## no critic
    plan skip_all => "because Net::EmptyPort required for testing" if $@;
}

use Test::NoWarnings;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
use Redis::JobQueue qw(
    DEFAULT_SERVER
    DEFAULT_PORT
    DEFAULT_TIMEOUT
    );
use Redis::JobQueue::Job qw(
    STATUS_CREATED
    STATUS_WORKING
    STATUS_COMPLETED
    STATUS_FAILED
    );
use Redis::JobQueue::Util qw(
    format_message
);

use Redis::JobQueue::Test::Utils qw(
    verify_redis
);

my $redis_error = "Unable to create test Redis server";
my ( $redis, $skip_msg, $port ) = verify_redis();

my $redis_addr = DEFAULT_SERVER.":$port";
my @redis_params = ( redis => $redis_addr );

SKIP: {
    diag $skip_msg if $skip_msg;
    skip( $skip_msg, 1 ) if $skip_msg;

# Test::RedisServer does not use timeout = 0
isa_ok( $redis, 'Test::RedisServer' );

#    my $jq = Redis::JobQueue->new();
my $jq = Redis::JobQueue->new( @redis_params );
isa_ok( $jq, 'Redis::JobQueue' );

my $pre_job = {
    queue       => 'lovely_queue',
    job         => 'strong_job',
    expire      => 12*60*60,
    };

my $job;
for ( 1..5 )
{
    note "$_ .. 5";
    $job = $jq->add_job( $pre_job );
    $job->started( time ) if $_ > 1;
    if ( $_ > 3 )
    {
        $job->failed( time );
    }
    elsif ( $_ > 2 )
    {
        $job->completed( time );
    }
    $jq->update_job( $job );
    sleep 1;
}
$jq->get_next_job( queue => $pre_job->{queue} );

foreach my $queue ( ( $pre_job->{queue}, $job ) )
{
    my $qstatus = $jq->queue_status( $queue );
    note "queue status = ", Dumper( $qstatus );

    is $qstatus->{length}, 4, 'correct length';
    is $jq->queue_length( $queue ), 4, 'correct queue_length';
    is $jq->queue_length( $job ), 4, 'correct queue_length';
    is $jq->queue_length( 'Wrong queue' ), 0, 'correct wrong queue length';
    is $qstatus->{all_jobs}, 5, 'correct all_jobs';
    ok $qstatus->{lifetime}, 'lifetime present';
    ok $qstatus->{max_job_age}, 'max_job_age present';
    ok exists( $qstatus->{min_job_age} ), 'min_job_age present';
}

$jq->delete_job( $job );

foreach my $queue ( ( $pre_job->{queue}, $job ) )
{
    my $qstatus = $jq->queue_status( $queue );
    note "queue status = ", Dumper( $qstatus );

    is $qstatus->{length}, 3, 'correct length';
    is $qstatus->{all_jobs}, 4, 'correct all_jobs';
    ok $qstatus->{lifetime}, 'lifetime present';
    ok $qstatus->{max_job_age}, 'max_job_age present';
    ok $qstatus->{min_job_age}, 'min_job_age present';
}

my $qstatus = $jq->queue_status( 'something_wrong' );
note "queue status = ", Dumper( $qstatus );
is $qstatus->{all_jobs}, 0, 'correct all_jobs';
is $qstatus->{length}, 0, 'correct length';
is scalar( keys %$qstatus ), 2, 'correct length';

dies_ok { $jq->queue_status } 'expecting to die - no args';

foreach my $queue ( ( undef, "", \"scalar", [] ) )
{
    dies_ok { $jq->queue_status( $queue ) } format_message( 'expecting to die (%s)', $queue );
}

};
