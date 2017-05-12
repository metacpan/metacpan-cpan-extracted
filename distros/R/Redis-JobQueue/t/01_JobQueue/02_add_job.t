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

my $server = DEFAULT_SERVER;
my $timeout = 1;


my $redis_error = "Unable to create test Redis server";
my ( $redis, $skip_msg, $port ) = verify_redis();

SKIP: {
    diag $skip_msg if $skip_msg;
    skip( $skip_msg, 1 ) if $skip_msg;

# For Test::RedisServer
isa_ok( $redis, 'Test::RedisServer' );

my ( $jq, $job, $resulting_job, $job2, $job3, $ret, @arr );
my $pre_job = {
    id          => '4BE19672-C503-11E1-BF34-28791473A258',
    queue       => 'lovely_queue',
    job         => 'strong_job',
    expire      => 300,
    status      => 'created',
    workload    => \'Some stuff up to 512MB long',
    result      => \'JOB result comes here, up to 512MB long',
    progress    => 0.1,
    message     => 'Some message',
    created     => time,
    started     => time,
    updated     => time,
    completed   => time,
    failed      => time,
    };

$jq = Redis::JobQueue->new(
    $redis,
    timeout => $timeout,
    );
isa_ok( $jq, 'Redis::JobQueue');

$jq->_call_redis( "DEL", $_ ) foreach $jq->_call_redis( "KEYS", "JobQueue:*" );

$job = Redis::JobQueue::Job->new(
    id           => $pre_job->{id},
    queue        => $pre_job->{queue},
    job          => $pre_job->{job},
    expire       => $pre_job->{expire},
    status       => $pre_job->{status},
    workload     => $pre_job->{workload},
    result       => $pre_job->{result},
    );
isa_ok( $job, 'Redis::JobQueue::Job');

$resulting_job = $jq->add_job(
    $pre_job,
    );
isa_ok( $resulting_job, 'Redis::JobQueue::Job');

is scalar( $job->modified_attributes ) - 1, scalar( keys %{$pre_job} ), "all fields are modified";

$resulting_job = $jq->add_job(
    $job,
    );
isa_ok( $resulting_job, 'Redis::JobQueue::Job');

$resulting_job = $jq->add_job(
    $job,
    LPUSH       => 1,
    );
isa_ok( $resulting_job, 'Redis::JobQueue::Job');

my $prev_id = $job->id;
my $added_job = $jq->add_job( $job );
is scalar( $job ), scalar( $added_job ), 'job is modified (address not changed)';
isnt $added_job->id, $prev_id, 'id changed';

#-------------------------------------------------------------------------------

dies_ok { $resulting_job = $jq->add_job(
    ) } "expecting to die";

foreach my $arg ( ( undef, 0, 0.5, 1, -1, -3, "", "0", "0.5", "1", 9999999999999999, \"scalar", [] ) )
{
    dies_ok { $resulting_job = $jq->add_job(
        $arg,
        ) } "expecting to die: ".( $arg || "" );
}

#-------------------------------------------------------------------------------

#$jq->_call_redis( "flushall" );

$job = $jq->add_job(
    $pre_job,
    );

ok $ret = $jq->_call_redis( 'EXISTS', Redis::JobQueue::NAMESPACE.":".$job->id ), "key exists: $ret";
ok $ret = $jq->_call_redis( 'EXISTS', Redis::JobQueue::NAMESPACE.":queue:".$job->queue ), "key exists: $ret";

$job->queue( "zzz" );

$jq->_call_redis( 'DEL', Redis::JobQueue::NAMESPACE.":queue:".$job->queue );

$job2 = $jq->add_job(
    $job,
    );

ok $ret = $jq->_call_redis( 'EXISTS', Redis::JobQueue::NAMESPACE.":".$job2->id ), "key exists: $ret";
ok $ret = $jq->_call_redis( 'EXISTS', Redis::JobQueue::NAMESPACE.":queue:".$job2->queue ), "key exists: $ret";

$job3 = $jq->add_job(
    $job2,
    );

is scalar( @arr = $jq->_call_redis( 'LRANGE', Redis::JobQueue::NAMESPACE.":queue:".$job2->queue, 0, -1 ) ), 2, "queue exists: @arr";
is scalar( @arr = $jq->_call_redis( 'HGETALL', Redis::JobQueue::NAMESPACE.":".$job2->id ) ), ( scalar keys %{$pre_job} ) * 2 + 2, "right hash"; # +2 for _SERVICE_FIELD

foreach my $field ( keys %{$pre_job} )
{
    if ( $field =~ /^workload|^result/ )
    {
        is $jq->_call_redis( 'HGET', Redis::JobQueue::NAMESPACE.":".$job2->id, $field ), ${$job2->$field}, "a valid value ($field = ".${$job2->$field}.")";
    }
    else
    {
        is $jq->_call_redis( 'HGET', Redis::JobQueue::NAMESPACE.":".$job2->id, $field ), $job2->$field, "a valid value ($field = ".$job2->$field.")";
    }
}

$jq->_call_redis( "DEL", $_ ) foreach $jq->_call_redis( "KEYS", "JobQueue:*" );

};
