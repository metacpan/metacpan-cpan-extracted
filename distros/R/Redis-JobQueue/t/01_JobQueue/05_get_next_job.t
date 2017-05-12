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

use Redis::JobQueue::Test::Utils qw(
    verify_redis
);

# options for testing arguments: ( undef, 0, 0.5, 1, -1, -3, "", "0", "0.5", "1", 9999999999999999, \"scalar", [] )

my $timeout = 1;

my $redis_error = "Unable to create test Redis server";
my ( $redis, $skip_msg, $port ) = verify_redis();

SKIP: {
    diag $skip_msg if $skip_msg;
    skip( $skip_msg, 1 ) if $skip_msg;

# For Test::RedisServer
isa_ok( $redis, 'Test::RedisServer' );

my ( $jq, $job, @jobs, $idx, @job_names, $to_left, $blocking, $name );
my $pre_job = {
    id           => '4BE19672-C503-11E1-BF34-28791473A258',
    queue        => 'lovely_queue',
    job          => 'strong_job',
    expire       => 30,
    status       => 'created',
    workload     => \'Some stuff up to 512MB long',
    result       => \'JOB result comes here, up to 512MB long',
    };

$jq = Redis::JobQueue->new(
    $redis,
    timeout => $timeout,
    );
isa_ok( $jq, 'Redis::JobQueue');

$jq->_call_redis( "DEL", $_ ) foreach $jq->_call_redis( "KEYS", "JobQueue:*" );

sleep 1;
foreach my $blocking ( ( 0, 1 ) )
{
    @job_names = ();
    my @ids = ();
    my @jbs = ();
    foreach my $name ( qw( yyy zzz ) )
    {
        push @job_names, $name;
        @jbs = ();
        foreach my $job_name ( @job_names )
        {
            $pre_job->{job} = $job_name;
            $job = Redis::JobQueue::Job->new( $pre_job );
            isa_ok( $job, 'Redis::JobQueue::Job');

            for ( 0..2 )
            {
                my $job = $jq->add_job( $job );
                push @jobs, $job;
                push @ids, $job->id;
                push @jbs, $job->job;
            }
            isa_ok( $jobs[ $_ ], 'Redis::JobQueue::Job' ) for ( 0..2 );
        }

        $idx = 0;
        while ( my $new_job = $jq->get_next_job(
            queue       => $pre_job->{queue},
            blocking    => $blocking,
            ) )
        {
            isa_ok( $new_job, 'Redis::JobQueue::Job' );

            foreach my $field ( keys %{$pre_job} )
            {
                if ( $field =~ /^workload|^result/ )
                {
                    is ${$new_job->$field}, ${$jobs[ $idx ]->$field}, "a valid data (".${$new_job->$field}.")";
                }
                elsif ( $field eq 'id' )
                {
                    for ( my $i = 0; $i <= $#ids; $i++ )
                    {
                        if ( $new_job->$field eq $ids[ $i ] )
                        {
                            is $new_job->$field, $ids[ $i ], "a valid $field (".$new_job->$field.")";
                            splice @ids, $i, 1;
                            last;
                        }
                    }
                }
                elsif ( $field eq 'job' )
                {
                    for ( my $i = 0; $i <= $#jbs; $i++ )
                    {
                        if ( $new_job->$field eq $jbs[ $i ] )
                        {
                            is $new_job->$field, $jbs[ $i ], "a valid $field (".$new_job->$field.")";
                            splice @jbs, $i, 1;
                            last;
                        }
                    }
                }
                else
                {
                    is $new_job->$field, $jobs[ $idx ]->$field, "a valid $field (".$new_job->$field.")";
                }
            }
            ++$idx;
        }
    }
}

$jq->_call_redis( "DEL", $_ ) foreach $jq->_call_redis( "KEYS", "JobQueue:*" );

$to_left = 1;
@jobs = ();
$name = "yyy";
$pre_job->{job} = $name;
$job = Redis::JobQueue::Job->new( $pre_job );
isa_ok( $job, 'Redis::JobQueue::Job');

unshift( @jobs, $jq->add_job( $pre_job, LPUSH => $to_left ) ) for ( 0..2 );
isa_ok( $jobs[ $_ ], 'Redis::JobQueue::Job' ) for ( 0..2 );

$idx = 0;
while ( my $new_job = $jq->get_next_job(
    queue       => $pre_job->{queue},
    ) )
{
    isa_ok( $new_job, 'Redis::JobQueue::Job' );

    foreach my $field ( keys %{$pre_job} )
    {
        if ( $field =~ /^workload|^result/ )
        {
            is ${$new_job->$field}, ${$jobs[ $idx ]->$field}, "a valid value (".${$new_job->$field}.")";
        }
        else
        {
            is $new_job->$field, $jobs[ $idx ]->$field, "a valid value (".$new_job->$field.")";
        }
    }
    ++$idx;
}

foreach my $arg ( ( "", \"scalar" ) )
{
    dies_ok { $jq->get_next_job(
        queue       => $arg,
        ) } "expecting to die: ".( $arg || "" );

    dies_ok { $jq->get_next_job(
        queue       => [ $arg ],
        ) } "expecting to die: ".( $arg || "" );
}

$blocking = 1;
$pre_job->{queue} = 'aaa';
$pre_job->{expire} = $timeout;
$job = Redis::JobQueue::Job->new( $pre_job );
isa_ok( $job, 'Redis::JobQueue::Job');
my $new_job = $jq->add_job( $job );
isa_ok( $new_job, 'Redis::JobQueue::Job' );
$new_job = $jq->get_next_job(
    queue       => $pre_job->{queue},
    blocking    => $blocking,
    );
isa_ok( $new_job, 'Redis::JobQueue::Job' );
$new_job = $jq->add_job( $job );
isa_ok( $new_job, 'Redis::JobQueue::Job' );
sleep $timeout * 2;
$new_job = $jq->get_next_job(
    queue       => $pre_job->{queue},
    blocking    => $blocking,
    );
is $new_job, undef, "job identifier has already been removed";

$blocking = 0;
$pre_job->{expire} = 0;

my @some_queues = qw( q1 q2 q3 );
my @some_jobs   = qw( j1 j2 j3 );
my @expectation = ();
foreach my $queue ( ( @some_queues ) )
{
    foreach my $job ( ( @some_jobs ) )
    {
        $pre_job->{queue}   = $queue;
        $pre_job->{job}     = $job;
        $new_job = $jq->add_job( $pre_job );
        push @expectation, "$queue $job";
    }
}

while ( my $job = $jq->get_next_job(
    queue       => \@some_queues,
    blocking    => 0,
    ) )
{
    for ( my $i = 0; $i <= $#expectation; $i++ )
    {
        if ( $job->queue.' '.$job->job eq $expectation[ $i ] )
        {
            is $job->queue.' '.$job->job, $expectation[ $i ], "job OK";
            splice @expectation, $i, 1;
            last;
        }
    }
}

#-------------------------------------------------------------------------------

@some_queues = qw( q1 q2 q3 );
@some_jobs   = qw( j1 j2 j3 );
@expectation = ();
my @combinations = ();
foreach my $queue ( ( @some_queues ) )
{
    foreach my $job ( ( @some_jobs ) )
    {
        $pre_job->{queue}   = $queue;
        $pre_job->{job}     = $job;
        $new_job = $jq->add_job( $pre_job );
        push @expectation, "[$queue $job]";
        push @combinations, [ $queue, $job ];
    }
}

$jq->_call_redis( "DEL", $_ ) foreach $jq->_call_redis( "KEYS", "JobQueue:*" );

#-- get_next_job

@some_queues = qw( q1 q2 q3 );
@some_jobs   = qw( j1 j2 j3 );
@expectation = ();
foreach my $queue ( ( @some_queues ) )
{
    foreach my $job ( ( @some_jobs ) )
    {
        $pre_job->{queue}   = $queue;
        $pre_job->{job}     = $job;
        $new_job = $jq->add_job( $pre_job );
        push @expectation, $new_job->id;
    }
}

while ( my $job_id = $jq->get_next_job_id(
    queue       => \@some_queues,
    blocking    => 0,
    ) )
{
    for ( my $i = 0; $i <= $#expectation; $i++ )
    {
        if ( $job_id eq $expectation[ $i ] )
        {
            pass "get_next_job_id OK ($job_id)";
            splice @expectation, $i, 1;
            last;
        }
    }
}

$jq->_call_redis( "DEL", $_ ) foreach $jq->_call_redis( "KEYS", "JobQueue:*" );

};
