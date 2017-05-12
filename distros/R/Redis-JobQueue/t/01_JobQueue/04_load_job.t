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
use Storable;

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

my ( $jq, $job, $new_job );
my $pre_job = {
    id           => '4BE19672-C503-11E1-BF34-28791473A258',
    queue        => 'lovely_queue',
    job          => 'strong_job',
    expire       => 300,
    status       => 'created',
    workload     => \'Some stuff up to 512MB long',
    result       => \Storable::nfreeze( \'JOB result comes here, up to 512MB long' ),
    };

$jq = Redis::JobQueue->new(
    $redis,
    timeout => $timeout,
    );
isa_ok( $jq, 'Redis::JobQueue');

$jq->_call_redis( "DEL", $_ ) foreach $jq->_call_redis( "KEYS", "JobQueue:*" );

$job = $jq->add_job( $pre_job );
isa_ok( $job, 'Redis::JobQueue::Job');

is scalar( $job->modified_attributes ), 0, "no modified fields";

$new_job = $jq->load_job( $job );
isa_ok( $new_job, 'Redis::JobQueue::Job');

is scalar( $new_job->modified_attributes ), 0, "no modified fields";

foreach my $field ( keys %{$pre_job} )
{
    if ( $field =~ /^workload|^result/ )
    {
        is ${$new_job->$field}, ${$job->$field}, "a valid value (".${$job->$field}.")";
    }
    else
    {
        is $new_job->$field, $job->$field, "a valid value (".$job->$field.")";
    }
}

$new_job = $jq->load_job( $job->id );
isa_ok( $job, 'Redis::JobQueue::Job');

dies_ok { $jq->load_job() } "expecting to die - no arguments";

foreach my $arg ( ( undef, "", \"scalar", [] ) )
{
    dies_ok { $jq->load_job( $arg ) } "expecting to die: ".( $arg || "" );
}

is $jq->load_job( "something wrong" ), undef, "job does not exist";

$jq->_call_redis( "DEL", $_ ) foreach $jq->_call_redis( "KEYS", "JobQueue:*" );

for my $test_data (
    12,
    [ 13, 14, 15 ],
    { a => 'b', c => 'd' },
    \'Hello, World',
    \'Hello, REF World',
    Storable::nfreeze( \'Data for Storable' ),
    \Storable::nfreeze( \'Data for Storable' ),
    $new_job,
    )
{
    $pre_job->{result} = $test_data;
    my $test_job = $jq->add_job( $pre_job );
    my $load_job = $jq->load_job( $test_job );
    if ( !ref( $test_data ) )
    {
# For scalar values 'workload' and 'result' ​​references returned
        is_deeply $load_job->result, \$pre_job->{result}, "OK $test_data";
    }
    else
    {
        is_deeply $load_job->result, $pre_job->{result}, "OK $test_data";
    }
}

};
