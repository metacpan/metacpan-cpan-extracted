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

    E_NO_ERROR
    );

use Redis::JobQueue::Job qw(
    STATUS_CREATED
    STATUS_WORKING
    STATUS_COMPLETED
    STATUS_FAILED
    );

use Redis::JobQueue::Test::Utils qw(
    get_redis
    verify_redis
);

my $redis_error = "Unable to create test Redis server";
my ( $redis, $skip_msg, $port ) = verify_redis();

SKIP: {
    diag $skip_msg if $skip_msg;
    skip( $skip_msg, 1 ) if $skip_msg;

    {
        no warnings;
        $Redis::CappedCollection::WAIT_USED_MEMORY = 1;
    }

my ( $jq, $job, @jobs, $maxmemory, $vm, $policy, $timeout );
my $pre_job = {
    id           => '4BE19672-C503-11E1-BF34-28791473A258',
    queue        => 'lovely_queue',
    job          => 'strong_job',
    expire       => 60,
    status       => 'created',
    workload     => \'Some stuff up to 512MB long',
    result       => \'JOB result comes here, up to 512MB long',
    };

sub new_connect {

    # For Test::RedisServer
    $port = Net::EmptyPort::empty_port( $port );
    $redis = get_redis( conf =>
        {
            port                => $port,
            maxmemory           => $maxmemory,
#            "vm-enabled"        => $vm,
            "maxmemory-policy"  => $policy,
            "maxmemory-samples" => 100,
        },
# Test::RedisServer does not use timeout = 0
        timeout => 3,
        );
    skip( $redis_error, 1 ) unless $redis;
    isa_ok( $redis, 'Test::RedisServer' );

    $jq = Redis::JobQueue->new(
        $redis,
        $timeout ? ( timeout => $timeout ) : (),
        );
    isa_ok( $jq, 'Redis::JobQueue');

    $jq->_call_redis( "DEL", $_ ) foreach $jq->_call_redis( "KEYS", "JobQueue:*" );
}

$maxmemory = 0;
$policy = "noeviction";
$timeout = 3;
new_connect();

$jq->_call_redis( "DEL", $_ ) foreach $jq->_call_redis( "KEYS", "JobQueue:*" );

$job = $jq->add_job( $pre_job );
isa_ok( $job, 'Redis::JobQueue::Job');

@jobs = $jq->get_job_ids;
ok scalar( @jobs ), "jobs exists";

#-- E_NO_ERROR

is $jq->last_errorcode, E_NO_ERROR, "E_NO_ERROR";
note '$@: ', $@;

#-- timeout

my $tm = time;
$job = $jq->get_next_job(
    queue    => 'not_lovely_queue',
    blocking => 1,
    );
ok time - $tm >= $timeout, "timeout ok";

$tm = time;
$job = $jq->get_next_job(
    queue    => 'lovely_queue',
    blocking => 0,
    );
ok time - $tm <= 1, "timeout ok";

#-- sample

new_connect();

my $queue = Redis::JobQueue->new(
    $redis,
    timeout => 3,
);

my @job_types = qw( foo bar );

say scalar localtime;
while( my $job = $queue->get_next_job(
    queue    => 'ts',
    blocking => 1,
))
{
    say "Got job: $job";
}
say scalar localtime;

#-- Closes and cleans up -------------------------------------------------------

$jq->_call_redis( "DEL", $_ ) foreach $jq->_call_redis( "KEYS", "JobQueue:*" );

ok $jq->_redis->ping, "server is available";
$jq->_redis->quit;
ok !$jq->_redis->ping, "no server";

};

exit;
