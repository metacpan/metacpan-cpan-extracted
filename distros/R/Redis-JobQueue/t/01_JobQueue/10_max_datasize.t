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

    E_DATA_TOO_LARGE
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

my ( $jq, $job, @jobs, $maxmemory, $vm, $policy );
my $pre_job = {
    id           => '4BE19672-C503-11E1-BF34-28791473A258',
    queue        => 'lovely_queue',
    job          => 'strong_job',
    expire       => 60,
    status       => 'created',
    workload     => \'Some stuff up to 512MB long',
    result       => \'JOB result comes here, up to 512MB long',
    };

my $maxmemory_mode;
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
        } );
    skip( $redis_error, 1 ) unless $redis;
    isa_ok( $redis, 'Test::RedisServer' );

    $jq = Redis::JobQueue->new(
        $redis,
        defined( $maxmemory_mode ) ? ( check_maxmemory => $maxmemory_mode ) : (),
        );
    isa_ok( $jq, 'Redis::JobQueue');

    $jq->_call_redis( "DEL", $_ ) foreach $jq->_call_redis( "KEYS", "JobQueue:*" );
}

#-- check_maxmemory argument

$maxmemory = 100;
new_connect();
is $jq->max_datasize, $maxmemory, 'max_datasize correct';

$maxmemory = int( Redis::JobQueue::MAX_DATASIZE / 2 );
$maxmemory_mode = 1;
new_connect();
is $jq->max_datasize, $maxmemory, 'max_datasize correct';
$maxmemory_mode = 0;
new_connect();
is $jq->max_datasize, Redis::JobQueue::MAX_DATASIZE, 'max_datasize correct';
undef $maxmemory_mode;

#-- Testing max_datasize

$maxmemory = 0;
$vm = "no";
$policy = "noeviction";
new_connect();

$jq->_call_redis( "DEL", $_ ) foreach $jq->_call_redis( "KEYS", "JobQueue:*" );

$job = $jq->add_job( $pre_job );
isa_ok( $job, 'Redis::JobQueue::Job');

@jobs = $jq->get_job_ids;
ok scalar( @jobs ), "jobs exists";

#-- E_DATA_TOO_LARGE

my $prev_max_datasize = $jq->max_datasize;
my $max_datasize = 100;
$pre_job->{result} .= '*' x ( $max_datasize + 1 );
$jq->max_datasize( $max_datasize );

$job = undef;
eval { $job = $jq->add_job( $pre_job ) };
is $jq->last_errorcode, E_DATA_TOO_LARGE, "E_DATA_TOO_LARGE";
note '$@: ', $@;
is $job, undef, "the job isn't changed";
$jq->max_datasize( $prev_max_datasize );

#-- Closes and cleans up -------------------------------------------------------

$jq->_call_redis( "DEL", $_ ) foreach $jq->_call_redis( "KEYS", "JobQueue:*" );

ok $jq->_redis->ping, "server is available";
$jq->_redis->quit;
ok !$jq->_redis->ping, "no server";

};

exit;
