#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

#use lib 'lib';
use lib 'lib', 't/tlib';

# WARNING: global file scope
#use utf8;
#use bytes;

use Test::More;
plan "no_plan";

BEGIN {
    eval "use Test::Exception";                 ## no critic
    plan skip_all => "because Test::Exception required for testing" if $@;
}

BEGIN {
    eval "use Test::Deep";                      ## no critic
    plan skip_all => "because Test::Deep required for testing" if $@;
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

use Redis::JobQueue::Test::Utils qw(
    get_redis
    verify_redis
);

my $redis_error = "Unable to create test Redis server";
my ( $redis_server, $skip_msg, $port ) = verify_redis();

my $redis_addr = DEFAULT_SERVER.":$port";

SKIP: {
    diag $skip_msg if $skip_msg;
    skip( $skip_msg, 1 ) if $skip_msg;

    my $redis = Redis->new( $redis_server->connect_info );
    lives_ok { $redis->quit } 'An object accept commands';


#-- just testing ---------------------------------------------------------------

my $err_msg;

# WARNING: In a test mode 'encoding' of the object '$redis' during writing and reading the same

#-- Controlling server connection

$port = Net::EmptyPort::empty_port( $port );
( $redis_server, $err_msg ) = get_redis( conf => { port => $port } );
skip( $err_msg, 1 ) unless $redis_server;
isa_ok( $redis_server, 'Test::RedisServer' );
$redis = Redis->new( $redis_server->connect_info );

# default encoding
ok !exists( $redis->{encoding} ), 'default encoding not exists';

$redis->quit;

#-- The behavior of the server itself
# Do not depend on the current:
#   - setting of 'use utf8;' or 'use bytes;'
#   - the place in which data is generated

my $file_euro       = "\x{20ac}";
my $file_bin        = "\x61\xE2\x98\xBA\x62";

{
    # utf8 - Perl pragma to enable/disable UTF-8 (or UTF-EBCDIC) in source code
    use utf8;                                   # in the current lexical scope

    my $euro    = "\x{20ac}";
    my $bin     = "\x61\xE2\x98\xBA\x62";

    $port = Net::EmptyPort::empty_port( $port );
    ( $redis_server, $redis_error ) = get_redis( conf => { port => $port } );
    skip( $redis_error, 1 ) unless $redis_server;
    $redis = Redis->new( $redis_server->connect_info );

# According to Redis documentation:
# There is no encoding feature anymore, it has been deprecated and finally removed.
# This module consider that any data sent to the Redis server is a binary data.
# And it doesn't do anything when getting data from the Redis server.
# So, if you are working with character strings, you should pre-encode or post-decode it if needed !

#    lives_ok { $redis->set( utf8 => $file_euro ) } 'set utf8';
#    dies_ok { $redis->set( utf8 => $file_euro ) } 'not set utf8';
#    ok !eq_deeply( $redis->get( 'utf8' ), $file_euro ), 'get not utf8';
#    lives_ok { $redis->set( utf8 => $euro ) } 'set utf8';
#    dies_ok { $redis->set( utf8 => $euro ) } 'not set utf8';
#    ok !eq_deeply( $redis->get( 'utf8' ), $euro ), 'get not utf8';
    ok $redis->set( bin => $file_bin ), 'set bin';
    is_deeply $redis->get( 'bin' ), $bin, 'get bin';

    $redis->quit;
}

{
    # disables character semantics for the rest of the lexical scope
    use bytes;

    my $euro    = "\x{20ac}";
    my $bin     = "\x61\xE2\x98\xBA\x62";

    $port = Net::EmptyPort::empty_port( $port );
    ( $redis_server, $redis_error ) = get_redis( conf => { port => $port } );
    skip( $redis_error, 1 ) unless $redis_server;
    $redis = Redis->new( $redis_server->connect_info );

# According to Redis documentation:
# There is no encoding feature anymore, it has been deprecated and finally removed.
# This module consider that any data sent to the Redis server is a binary data.
# And it doesn't do anything when getting data from the Redis server.
# So, if you are working with character strings, you should pre-encode or post-decode it if needed !

#    lives_ok { $redis->set( utf8 => $file_euro ) } 'set utf8';
#    dies_ok { $redis->set( utf8 => $file_euro ) } 'not set utf8';
#    ok !eq_deeply( $redis->get( 'utf8' ), $file_euro ), 'get not utf8';
#    lives_ok { $redis->set( utf8 => $euro ) } 'set utf8';
#    dies_ok { $redis->set( utf8 => $euro ) } 'not set utf8';
#    ok !eq_deeply( $redis->get( 'utf8' ), $euro ), 'get not utf8';
    ok $redis->set( bin => $file_bin ), 'set bin';
    is_deeply $redis->get( 'bin' ), $bin, 'get bin';

    $redis->quit;
}

#-- The behavior of the Redis::JobQueue

# Checking the ordinary fields
{
    # utf8 - Perl pragma to enable/disable UTF-8 (or UTF-EBCDIC) in source code
    use utf8;                                   # in the current lexical scope

    for my $data ( (
            $file_euro,
            $file_bin,
        ) ) {

        $port = Net::EmptyPort::empty_port( $port );
        ( $redis_server, $redis_error ) = get_redis( conf => { port => $port } );
        skip( $redis_error, 1 ) unless $redis_server;
        $redis = Redis->new( $redis_server->connect_info );
        my $pre_job = {
            queue       => 'lovely_queue',
            job         => 'strong_job',
            expire      => 12*60*60,
            status      => $data,
        };

        my $jq = Redis::JobQueue->new( $redis );
        my $added_job;

        if ( $data eq $file_euro ) {
            dies_ok { $added_job = $jq->add_job( $pre_job ) } 'not set utf8' if $data eq $file_euro;
        } elsif ( $data eq $file_bin ) {
            lives_ok { $added_job = $jq->add_job( $pre_job ) } 'set not utf8' if $data eq $file_bin;

            my $status = $jq->get_job_data( $added_job, 'status' );
            is_deeply $status, $pre_job->{status}, 'correct loaded status';

            my $new_job = $jq->load_job( $added_job );
            is_deeply $new_job->status, $pre_job->{status}, 'correct loaded status';
        }

        $redis->quit;
    }
}

{
    # disables character semantics for the rest of the lexical scope
    use bytes;

    for my $data ( (
            $file_euro,
            $file_bin,
        ) ) {

        $port = Net::EmptyPort::empty_port( $port );
        ( $redis_server, $redis_error ) = get_redis( conf => { port => $port } );
        skip( $redis_error, 1 ) unless $redis_server;
        $redis = Redis->new( $redis_server->connect_info );
        my $pre_job = {
            queue       => 'lovely_queue',
            job         => 'strong_job',
            expire      => 12*60*60,
            status      => $data,
        };

        my $jq = Redis::JobQueue->new( $redis );
        my $added_job;

        if ( $data eq $file_euro ) {
            dies_ok { $added_job = $jq->add_job( $pre_job ) } 'not set utf8' if $data eq $file_euro;
        } elsif ( $data eq $file_bin ) {
            lives_ok { $added_job = $jq->add_job( $pre_job ) } 'set not utf8' if $data eq $file_bin;

            my $status = $jq->get_job_data( $added_job, 'status' );
            is_deeply $status, $pre_job->{status}, 'correct loaded status';

            my $new_job = $jq->load_job( $added_job );
            is_deeply $new_job->status, $pre_job->{status}, 'correct loaded status';
        }

        $redis->quit;
    }
}

# Checking the serialized fields
{
    # utf8 - Perl pragma to enable/disable UTF-8 (or UTF-EBCDIC) in source code
    use utf8;                                   # in the current lexical scope

    for my $data ( (
            $file_euro,
            $file_bin,
        ) ) {

        $port = Net::EmptyPort::empty_port( $port );
        ( $redis_server, $redis_error ) = get_redis( conf => { port => $port } );
        skip( $redis_error, 1 ) unless $redis_server;
        $redis = Redis->new( $redis_server->connect_info );
        my $pre_job = {
            queue       => 'lovely_queue',
            job         => 'strong_job',
            expire      => 12*60*60,
            result      => \$data,
            meta_data   => {
                foo     => $data,
            },
        };

        my $jq = Redis::JobQueue->new( $redis );
        my $added_job;

        lives_ok { $added_job = $jq->add_job( $pre_job ) } 'set utf8';

        my $foo = $jq->get_job_data( $added_job, 'foo' );
        is_deeply $foo, $pre_job->{meta_data}->{foo}, 'correct loaded foo';

        my $new_job = $jq->load_job( $added_job );
        is_deeply $new_job->result, $pre_job->{result}, 'correct loaded result';
        is_deeply $new_job->meta_data( 'foo' ), $pre_job->{meta_data}->{foo}, 'correct loaded foo';

        $redis->quit;
    }
}

{
    # disables character semantics for the rest of the lexical scope
    use bytes;

    for my $data ( (
            $file_euro,
            $file_bin,
        ) ) {

        $port = Net::EmptyPort::empty_port( $port );
        ( $redis_server, $redis_error ) = get_redis( conf => { port => $port } );
        skip( $redis_error, 1 ) unless $redis_server;
        $redis = Redis->new( $redis_server->connect_info );
        my $pre_job = {
            queue       => 'lovely_queue',
            job         => 'strong_job',
            expire      => 12*60*60,
            result      => \$data,
            meta_data   => {
                foo     => $data,
            },
        };

        my $jq = Redis::JobQueue->new( $redis );
        my $added_job;

        lives_ok { $added_job = $jq->add_job( $pre_job ) } 'set utf8';

        my $foo = $jq->get_job_data( $added_job, 'foo' );
        is_deeply $foo, $pre_job->{meta_data}->{foo}, 'correct loaded foo';

        my $new_job = $jq->load_job( $added_job );
        is_deeply $new_job->result, $pre_job->{result}, 'correct loaded result';
        is_deeply $new_job->meta_data( 'foo' ), $pre_job->{meta_data}->{foo}, 'correct loaded foo';

        $redis->quit;
    }
}

#-- Everything is working correctly, if the data is "protected"

# Checking the ordinary fields
{
    # utf8 - Perl pragma to enable/disable UTF-8 (or UTF-EBCDIC) in source code
    use utf8;                                   # in the current lexical scope

    for my $data ( (
            $file_euro,
            $file_bin,
        ) ) {

        $port = Net::EmptyPort::empty_port( $port );
        ( $redis_server, $redis_error ) = get_redis( conf => { port => $port } );
        skip( $redis_error, 1 ) unless $redis_server;
        $redis = Redis->new( $redis_server->connect_info );

        # data is "protected"
        my $status = $data;
        utf8::encode( $status );

        my $pre_job = {
            queue       => 'lovely_queue',
            job         => 'strong_job',
            expire      => 12*60*60,
            status      => $status,
        };

        my $jq = Redis::JobQueue->new( $redis );
        my $added_job;

        lives_ok { $added_job = $jq->add_job( $pre_job ) } 'set utf8';

        my $new_status = $jq->get_job_data( $added_job, 'status' );
        utf8::decode( $new_status );
        is_deeply $new_status, $data, 'correct loaded status';

        my $new_job = $jq->load_job( $added_job );
        $new_status = $new_job->status;
        utf8::decode( $new_status );
        is_deeply $new_status, $data, 'correct loaded status';

        $redis->quit;
    }
}

# Checking the ordinary fields
{
    # disables character semantics for the rest of the lexical scope
    use bytes;
    use Encode;

    for my $data ( (
            $file_euro,
            $file_bin,
        ) ) {

        $port = Net::EmptyPort::empty_port( $port );
        ( $redis_server, $redis_error ) = get_redis( conf => { port => $port } );
        skip( $redis_error, 1 ) unless $redis_server;
        $redis = Redis->new( $redis_server->connect_info );

        # data is "protected"
# The "problem" applies only to text fields 'status', 'message'
        my $status = Encode::encode_utf8( $data );

        my $pre_job = {
            queue       => 'lovely_queue',
            job         => 'strong_job',
            expire      => 12*60*60,
            status      => $status,
        };

        my $jq = Redis::JobQueue->new( $redis );
        my $added_job;

        lives_ok { $added_job = $jq->add_job( $pre_job ) } 'set utf8';

        my $new_status = $jq->get_job_data( $added_job, 'status' );
        $new_status = Encode::decode_utf8( $new_status );
        is_deeply $new_status, $data, 'correct loaded status';

        my $new_job = $jq->load_job( $added_job );
        $new_status = $new_job->status;
        is_deeply( ( utf8::is_utf8( $new_status ) ? $new_status : Encode::decode_utf8( $new_job->status ) ), $data, 'correct loaded status' );

        $redis->quit;
    }
}

{
    # disables character semantics for the rest of the lexical scope
    use bytes;

    for my $data ( (
            $file_euro,
            $file_bin,
        ) ) {

        $port = Net::EmptyPort::empty_port( $port );
        ( $redis_server, $redis_error ) = get_redis( conf => { port => $port } );
        skip( $redis_error, 1 ) unless $redis_server;
        $redis = Redis->new( $redis_server->connect_info );

        # data is "protected"
        my $status = $data;
        utf8::encode( $status );

        my $pre_job = {
            queue       => 'lovely_queue',
            job         => 'strong_job',
            expire      => 12*60*60,
            status      => $status,
        };

        my $jq = Redis::JobQueue->new( $redis );
        my $added_job;

        lives_ok { $added_job = $jq->add_job( $pre_job ) } 'set utf8';

        my $new_status = $jq->get_job_data( $added_job, 'status' );
        utf8::decode( $new_status );
        is_deeply $new_status, $data, 'correct loaded status';

        my $new_job = $jq->load_job( $added_job );
        $new_status = $new_job->status;
        utf8::decode( $new_status );
        is_deeply $new_status, $data, 'correct loaded status';

        $redis->quit;
    }
}

# For non-serialized fields: UTF8 can not be transferred to the server Redis
{
    # utf8 - Perl pragma to enable/disable UTF-8 (or UTF-EBCDIC) in source code
    use utf8;                                   # in the current lexical scope

    foreach my $data ( (
            [ status    => $file_euro ],
            [ message   => $file_euro ],
        ) ) {

        $port = Net::EmptyPort::empty_port( $port );
        ( $redis_server, $redis_error ) = get_redis( conf => { port => $port } );
        skip( $redis_error, 1 ) unless $redis_server;
        $redis = Redis->new( $redis_server->connect_info );

        my $pre_job = {
            queue       => 'lovely_queue',
            job         => 'strong_job',
            expire      => 12*60*60,
            @$data,
        };

        my $jq = Redis::JobQueue->new( $redis );
        my $added_job;

        dies_ok { $added_job = $jq->add_job( $pre_job ) } 'an attempt set utf8';
        like $@, qr/Invalid argument \(utf8 in \w+\)/, 'correct exception';

        $redis->quit;
    }
}

{
    # disables character semantics for the rest of the lexical scope
    use bytes;

    foreach my $data ( (
            [ status    => $file_euro ],
            [ message   => $file_euro ],
        ) ) {

        $port = Net::EmptyPort::empty_port( $port );
        ( $redis_server, $redis_error ) = get_redis( conf => { port => $port } );
        skip( $redis_error, 1 ) unless $redis_server;
        $redis = Redis->new( $redis_server->connect_info );

        my $pre_job = {
            queue       => 'lovely_queue',
            job         => 'strong_job',
            expire      => 12*60*60,
            @$data,
        };

        my $jq = Redis::JobQueue->new( $redis );
        my $added_job;

        dies_ok { $added_job = $jq->add_job( $pre_job ) } 'an attempt set utf8';
        like $@, qr/Invalid argument \(utf8 in \w+\)/, 'correct exception';

        $redis->quit;
    }
}

};
