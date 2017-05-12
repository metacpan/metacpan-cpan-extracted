#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

use lib qw(
    lib
    t/tlib
);

use Test::More;
plan 'no_plan';

#-- work conditions
my (
    $MAXMEMORY,
    $MAXCLIENTS,
    $MEMORY_RESERVE,
    $CHILDREN,
    $OPERATIONS,
    $DEBUG,
    $WAIT_USED_MEMORY,
    $CONCURENT_CHILD,
    $CONCURRENT_FORKS,
    $CONCURRENT_OPERATIONS,
    $LUA_TIME_LIMIT,
    $MAX_WORKING_CYCLES
);

#NOTE: $MAXMEMORY below value used only when test without script arguments
$MAXMEMORY              = 70 * 1024 * 1024; # minimum for avoid 'used_memory > maxmemory' problem
$MEMORY_RESERVE         = 0.05; # 0.05 is Redis::CappedCollection default
$MAXCLIENTS             = 63;
#$MAXCLIENTS             = 10_000;
# work sockets:
#     Test::RedisServer's socket
#   + first test's collection socket
#   + parent's work collection socket
#   + $CHILDREN's sockets
$CHILDREN               = $MAXCLIENTS - 3;
#$CHILDREN               = 40;
$OPERATIONS             = 100;
$DEBUG                  = 1;        # logging: $DEBUG > 0 for 'used_memory > maxmemory' waiting, 2 and 3 for operation durations logging
$WAIT_USED_MEMORY       = 1;
#$CONCURENT_CHILD        = $CHILDREN;
$CONCURENT_CHILD        = 40;
$CONCURRENT_FORKS       = 250_000;
$CONCURRENT_OPERATIONS  = 1;        # 0 for more 'Could not connect to Redis server' problems
$LUA_TIME_LIMIT         = 5_000;    # ms (default 5_000)
$MAX_WORKING_CYCLES     = 0;        # for $Redis::CappedCollection::_MAX_WORKING_CYCLES (default 10_000_000)
                                    # i.e. for Redis::CappedCollection->_long_term_operation method.
                                    # if 0 than child works without Redis::CappedCollection->_long_term_operation calling

our ( $_SERVER_ADDRESS, $_COLLECTION_NAME, $_WORK_MODE, $_PASSWORD );
BEGIN {
    use Getopt::Long qw(
        GetOptions
    );

    my $help;

    my $ret = GetOptions(
        'server:s'      => \$_SERVER_ADDRESS,
        'collection:s'  => \$_COLLECTION_NAME,
        'mode:s'        => \$_WORK_MODE,
        'password:s'    => \$_PASSWORD,
        "help|?"        => \$help,
    );

    if ( $help ) {
        say <<"HELP";
Usage: $0 [--server="..."] [--collection=...] [--mode="..."] [--password="..."] [--help]

Open existing Redis::CappedCollection collection, dump collection data content.

Options:
    --help
        Display this help and exit.

    --server="..."
        The server should contain an IP_address:port of Redis server.
    --collection="..."
        The collection name.
    --mode="..."
        'create'  - connect to 'server' and create/fill 'collection'.
        'connect' - connecto to 'server' and tests on existing 'collection'.
        Redis server must be started manually before in both cases.
    --password="..."
        If your Redis server requires authentication, you can use the password argument.

    All or none of arguments must be present.

    Example redis server command string:
        ./redis-server --maxmemory-policy noeviction --maxmemory 36mb

    Example script command strings:
        $0 --server 127.0.0.1:6379 --collection SomeCollection --mode create
        $0 --server 127.0.0.1:6379 --collection SomeCollection --mode connect
    or
        $0
HELP
        exit 1;
    }

    if ( $_SERVER_ADDRESS && $_COLLECTION_NAME && $_WORK_MODE ) {
        BAIL_OUT( "wrong 'server' argument" )
            unless $_SERVER_ADDRESS =~ /^[0-9.]+:\d+$/;
        ;
        BAIL_OUT( "wrong 'mode' script argument" )
            unless $_WORK_MODE eq 'create' || $_WORK_MODE eq 'connect'
        ;
    } elsif ( $_SERVER_ADDRESS || $_COLLECTION_NAME || $_WORK_MODE ) {
        BAIL_OUT( 'wrong script arguments' );
    }

    $_PASSWORD = $_PASSWORD ? [ password => $_PASSWORD ] : [];
}

BEGIN {
    unless ( $_SERVER_ADDRESS ) {
        eval 'use Test::RedisServer';               ## no critic
        plan skip_all => 'because Test::RedisServer required for testing' if $@;
    }
}

BEGIN {
    unless ( $_SERVER_ADDRESS ) {
        eval 'use Net::EmptyPort';                  ## no critic
        plan skip_all => 'because Net::EmptyPort required for testing' if $@;
    }
}

BEGIN {
    eval 'use Test::Exception';                 ## no critic
    plan skip_all => 'because Test::Exception required for testing' if $@;
}

BEGIN {
    unless ( $_SERVER_ADDRESS ) {
        eval(                                   ## no critic;
            '
                use Data::UUID;
                use Redis::CappedCollection::Test::Utils qw(
                    get_redis
                    verify_redis
                );
            '
        );
        plan skip_all => 'because Data::UUID, Redis::CappedCollection::Test::Utils required for testing' if $@;
    }
}

use List::Util qw(
    shuffle
);
use Params::Util qw(
    _INSTANCE
);
use POSIX ':sys_wait_h';
use Redis;
use Time::HiRes ();
use Try::Tiny;

use Redis::CappedCollection qw(
    $DEFAULT_SERVER
);

STDOUT->autoflush;

# NOTE: No default CPAN testing now because it's so long...
unless ( $ENV{AUTHOR_TESTS} ) {
    pass 'No testing now';
    exit;
}

# -- Global variables

$Redis::CappedCollection::DEBUG                 = $DEBUG;
$Redis::CappedCollection::WAIT_USED_MEMORY      = $WAIT_USED_MEMORY;
$Redis::CappedCollection::_MAX_WORKING_CYCLES   = $MAX_WORKING_CYCLES;

#-- data variables
my $LIST_ID         = 'Some list_id';
my $data_length     = 200;
my $STUFF           = '*' x $data_length;
my $MAXMEMORY_STR   = sprintf( '%.2f mb', $MAXMEMORY / ( 1024 * 1024 ) );
my ( $uuid, $COLLECTION_NAME, $SERVER, $SERVER_PORT );
if ( $_SERVER_ADDRESS ) {
    $COLLECTION_NAME = $_COLLECTION_NAME;
    ( $SERVER, $SERVER_PORT ) = split ':', $_SERVER_ADDRESS;
} else {
    $uuid = Data::UUID->new unless $_COLLECTION_NAME;
    $SERVER = $DEFAULT_SERVER;
}

#-- utility variables
my $CHILD_MODE      = {
    receive => 0,
    insert  => 0,
};
my @DATA_IDS;
my @CHILD_PIDS;
my $ATTEMPTS;

my ( $REDIS_SERVER, $error_msg, $start_port );

if ( $_SERVER_ADDRESS ) {
    if ( $_WORK_MODE eq 'create' ) {
        create_remote_collection();
    } elsif ( $_WORK_MODE eq 'connect' ) {
        my $collection = connect_remote_collection();

        pass sprintf( '%s initial conditions: DEBUG = %d, maxmemory = %s, forks = %d, operations = %d',
            get_time_str(),
            $DEBUG // 0,
            sprintf( '%0.2fmb', $MAXMEMORY / ( 1024 * 1024 ) ),
            $CHILDREN,
            $OPERATIONS
        );

        concurrent_forks_testing( $collection );
        testing_remote_collection( $collection );
    }
} else {
    ( $REDIS_SERVER, $error_msg, $start_port ) = verify_redis( $_PASSWORD ? $_PASSWORD->[1] : undef );

    SKIP: {
        diag $error_msg if $error_msg;
        skip( $error_msg, 1 ) if $error_msg;

        concurrent_forks_testing();
        testing();
    }
}

exit;

#-------------------------------------------------------------------------------

sub create_remote_collection {
    my $redis_settings = {
        server => $_SERVER_ADDRESS,
        @$_PASSWORD,
    };
    my $collection;
    if ( Redis::CappedCollection::collection_exists( redis => $redis_settings, name => $COLLECTION_NAME ) ) {
        $collection = Redis::CappedCollection->open(
            redis               => $redis_settings,
            name                => $COLLECTION_NAME,
            reconnect_on_error  => 1,
        );
    } else {
        $collection = Redis::CappedCollection->create(
            redis               => $redis_settings,
            name                => $COLLECTION_NAME,
            memory_reserve      => $MEMORY_RESERVE,
            older_allowed       => 1,
            reconnect_on_error  => 1,
        );
    }
    BAIL_OUT( get_time_str().' Cannot connect to redis server' ) unless $collection;
    isa_ok( $collection, 'Redis::CappedCollection' );
    ok $collection->ping, 'collection available';

    my $redis = $collection->_redis;
    $MAXMEMORY = $redis->config_get( 'maxmemory' )->[1];
    BAIL_OUT( get_time_str()." redis server 'maxmemory' must be set" ) unless $MAXMEMORY;

    $collection->clear_collection;
    $collection->_wait_used_memory;
    while ( 1 ) {
        my $data_time   = Time::HiRes::time();
        my $data_id     = $data_time;
        my $result = try {
            $collection->upsert( $LIST_ID, $data_id, $STUFF, $data_time );
        } catch {
            my $error = $_;
            BAIL_OUT( get_time_str()."BAD upsert: $error" );
        };
        BAIL_OUT( 'upsert: Cannot insert into collection' ) unless $result;

        my $info = get_collection_info( $collection );
        last if !%$info || $info->{last_removed_time}; # cleaning executed
    }
    $collection->_wait_used_memory;

    my $items = get_collection_info( $collection )->{items};
    pass sprintf( "%s collection '%s' on '%s' filled: items = %s",
        scalar( localtime ),
        $COLLECTION_NAME,
        $_SERVER_ADDRESS,
        $items,
    );
}

sub connect_remote_collection {
    my $redis_settings = {
        server => $_SERVER_ADDRESS,
        @$_PASSWORD,
    };
    my $collection;
    if ( Redis::CappedCollection::collection_exists( redis => $redis_settings, name => $COLLECTION_NAME ) ) {
        $collection = Redis::CappedCollection->open(
            redis               => $redis_settings,
            name                => $COLLECTION_NAME,
            reconnect_on_error  => 1,
        );
    } else {
        BAIL_OUT( get_time_str()." Collection '$COLLECTION_NAME' on '$_SERVER_ADDRESS' not available" );
    }
    BAIL_OUT( get_time_str().' Cannot connect to redis server' ) unless $collection;
    isa_ok( $collection, 'Redis::CappedCollection' );
    ok $collection->ping, 'collection available';

    my $redis = $collection->_redis;
    $MAXMEMORY = $redis->config_get( 'maxmemory' )->[1];
    BAIL_OUT( get_time_str()." redis server 'maxmemory' must be set" ) unless $MAXMEMORY;

    $collection->_wait_used_memory;

    my $items = get_collection_info( $collection )->{items};

    pass sprintf( "%s collection '%s' on '%s' filled: items = %s",
        get_time_str(),
        $COLLECTION_NAME,
        $_SERVER_ADDRESS,
        $items,
    );

    return $collection;
}

sub testing_remote_collection {
    my ( $collection ) = @_;

    foreach my $mode (
#            { receive => 1, insert => 0 },
#            { receive => 0, insert => 1 },
            { receive => 1, insert => 1 },
        )
    {
        $CHILD_MODE = $mode;
        my $info = get_collection_info( $collection );
        pass sprintf( '%s START: receive/insert = %d/%d, used_memory = %s, items = %s',
            get_time_str(),
            $mode->{receive},
            $mode->{insert},
            get_used_memory_str( $collection ),
            $info->{items} // '<undef>'
        );

        start_children();
        wait_until_children();

        $info = get_collection_info( $collection );
        pass sprintf( '%s FINISH: used_memory = %s, items = %s',
            get_time_str(),
            get_used_memory_str( $collection ),
            $info->{items} // '<undef>'
        );
    }
}

sub testing {
    my ( $error_msg, $collection ) = create_collection( $start_port );
    skip( $error_msg, 1 ) unless $collection;
    undef $collection;

    $collection = open_connection();
    ok $collection->ping, 'collection available';
    if ( $collection ) {
        pass sprintf( '%s initial conditions: DEBUG = %d, maxmemory = %s, forks = %d, operations = %d, lua-time-limit = %d',
            get_time_str(),
            $DEBUG // 0,
            $MAXMEMORY_STR,
            $CHILDREN,
            $OPERATIONS,
            $LUA_TIME_LIMIT,
        );
        foreach my $mode (
#                { receive => 1, insert => 0 },
#                { receive => 0, insert => 1 },
                { receive => 1, insert => 1 },
            )
        {
            $CHILD_MODE = $mode;
            filling( $collection );
            my $info = get_collection_info( $collection );
            pass sprintf( '%s START: receive/insert = %d/%d, used_memory = %s, items = %s',
                get_time_str(),
                $mode->{receive},
                $mode->{insert},
                get_used_memory_str( $collection ),
                $info->{items} // '<undef>'
            );

            start_children();
            wait_until_children();

            $info = get_collection_info( $collection );
            pass sprintf( '%s FINISH: used_memory = %s, items = %s',
                get_time_str(),
                get_used_memory_str( $collection ),
                $info->{items} // '<undef>'
            );
        }
    }
}

sub get_used_memory_str {
    my ( $collection ) = @_;

    return sprintf( '%0.2fmb', get_used_memory( $collection ) / ( 1024 * 1024 ) );
}

sub get_used_memory {
    my ( $collection ) = @_;

    return $collection->_redis->info( 'memory' )->{used_memory};
}

sub get_collection_info {
    my ( $collection ) = @_;

    my $info = try {
        $collection->collection_info;
    } catch {
        my $error = $_;
        BAIL_OUT get_time_str()." BAD collection_info: $error";
    };

    return( $info // {} );
}

sub start_children {
    $ATTEMPTS = $CHILDREN;
    while ( $ATTEMPTS-- )
    {
        my $child_pid = fork;
        if ( $child_pid ) {
            push @CHILD_PIDS, $child_pid;
        } elsif ( defined $child_pid ) {
            my $ppid = getppid();
            child_work( $ppid );
            exit 0;
        } else {
            BAIL_OUT get_time_str().' An unexpected error (fork)';
        }
    }
}

sub child_work {
    my ( $ppid ) = @_;

    my $collection  = open_connection();
    my $receives    = 0;
    my $inserts     = 0;
    my $start_tm    = Time::HiRes::time;
    for ( 1 .. $OPERATIONS ) {
        my $mode = ( shuffle( grep( $CHILD_MODE->{ $_ }, keys %$CHILD_MODE ) ) )[0];
        if ( $CHILD_MODE->{insert} )
        {
            if ( $mode eq 'receive' )
            {
                pop_oldest( $collection );
                ++$receives;
            }
            else
            {
                insert_data( $collection, $$, $ppid );
                ++$inserts;
            }
        }
        elsif ( $mode eq 'receive' )
        {
            if ( $_SERVER_ADDRESS ) {
                pop_oldest( $collection );
            } else {
                my $data_id = $DATA_IDS[ int( rand scalar @DATA_IDS ) ];
                my $data = try {
                    $collection->receive( $LIST_ID, $data_id );
                } catch {
                    my $error = $_;
                    BAIL_OUT get_time_str()." [$$] BAD receive: $error";
                };
                BAIL_OUT( get_time_str()." receive: BAD received data (received = '".( $data // '<undef>' )."')" ) unless $data && $data eq $STUFF;
            }
            ++$receives;
        }
        else
        {
            # nothing to do
        }
    }
    my $finish_tm = Time::HiRes::time;
    say sprintf( '[%d] operations per sec: %.2f', $$, $OPERATIONS / ( $finish_tm - $start_tm ) );
#    say "[$$] receives = $receives, inserts = $inserts";
}

sub pop_oldest {
    my ( $collection ) = @_;

    my ( $list_id, $data );
    try {
        ( $list_id, $data ) = $collection->pop_oldest;
    } catch {
        my $error = $_;
        BAIL_OUT get_time_str()." [$$] BAD pop_oldest: $error";
    };
    if ( $list_id ) {
        BAIL_OUT( get_time_str().' pop_oldest: BAD popped data' ) unless $data && $data eq $STUFF;
    } else {
#        my $info = get_collection_info( $collection );
#        say 'the collection does not contain any data: items = '.( $info->{items} // '<undef>' );
    }
}

sub wait_until_children {
    waitpid $_, 0 for @CHILD_PIDS;
    @CHILD_PIDS = ();
}

sub filling {
    my ( $collection ) = @_;

    $collection->clear_collection;
#    pass "collection cleared: items = ".get_collection_info( $collection )->{items};
    @DATA_IDS = ();

    $collection->_wait_used_memory;
    my $inserts = 0;
    while ( 1 ) {
        my $data_id = insert_data( $collection );
        ++$inserts;
        push @DATA_IDS, $data_id;

        my $info = get_collection_info( $collection );
        last if !%$info || $info->{last_removed_time}; # cleaning executed
    }
    $collection->_wait_used_memory;

    my $items = get_collection_info( $collection )->{items};
    shift( @DATA_IDS ) while scalar( @DATA_IDS ) > $items;

#    pass "filling: inserts = $inserts";
    return $inserts;
}

sub insert_data {
    my ( $collection, $pid, $ppid ) = @_;

    my $data_time   = Time::HiRes::time();
    my $data_id     = $data_time;

    my $result = try {
        $collection->upsert( $LIST_ID, $data_id, $STUFF, $data_time );
    } catch {
        my $error = $_;
        BAIL_OUT( ( $pid ? get_time_str()." [$pid] " : '' )."BAD upsert: $error" );
    };
    BAIL_OUT( get_time_str().' upsert: Cannot insert into collection' ) unless $result;

    return $data_id;
}

sub long_term_operation {
    my ( $collection, $pid, $ppid ) = @_;

    my $result = try {
        $collection->_long_term_operation();
    } catch {
        my $error = $_;
        BAIL_OUT( ( $pid ? get_time_str()." [$pid] " : '' )."BAD upsert: $error" );
    };
    BAIL_OUT( get_time_str().' upsert: Cannot insert into collection' ) unless $result;

    return;
}

sub display_maxclients {
    my ( $definition ) = @_;

    my $control_redis = Redis->new( $REDIS_SERVER->connect_info, @$_PASSWORD );
    my $maxclient = $control_redis->config_get( 'maxclients' )->[1];
    pass "$definition redis server maxclients: $maxclient";
    undef $control_redis;
}

sub create_collection {
    my ( $port ) = @_;

    display_maxclients( 'Default' );

    $COLLECTION_NAME = $uuid->create_str,

    $REDIS_SERVER->stop;
    undef $REDIS_SERVER;

    $SERVER_PORT = Net::EmptyPort::empty_port( $port );
    my $error_msg;
    ( $REDIS_SERVER, $error_msg ) = get_redis(
        conf => {
            port                => $SERVER_PORT,
            'maxmemory-policy'  => 'noeviction',
            maxmemory           => $MAXMEMORY,
# NOTE:
# Set the max number of connected clients at the same time. By default
# this limit is set to 10000 clients, however if the Redis server is not
# able to configure the process file limit to allow for the specified limit
# the max number of allowed clients is set to the current file limit
# minus 32 (as Redis reserves a few file descriptors for internal uses).
#
# Once the limit is reached Redis will close all the new connections sending
# an error 'max number of clients reached'.
#
            $MAXCLIENTS ? ( maxclients => $MAXCLIENTS ) : (),
            $_PASSWORD ? ( requirepass => $_PASSWORD->[1] ) : (),
            $LUA_TIME_LIMIT ? ( 'lua-time-limit' => $LUA_TIME_LIMIT ) : (),
        },
    );
    return $error_msg unless $REDIS_SERVER;
    isa_ok( $REDIS_SERVER, 'Test::RedisServer' );
    say 'Redis server tmpdir: '.$REDIS_SERVER->tmpdir;

    display_maxclients( 'Work' );

    my $collection = Redis::CappedCollection->create(
        redis               => $REDIS_SERVER,
        name                => $COLLECTION_NAME,
        memory_reserve      => $MEMORY_RESERVE,
        older_allowed       => 1,
        reconnect_on_error  => 1,
    );
    isa_ok( $collection, 'Redis::CappedCollection' );
    ok $collection->ping, 'collection available';

    my $redis = $collection->_redis;
    isa_ok( $redis, 'Redis' );
    ok $redis->ping, 'redis server available';

    return( $error_msg, $collection );
}

sub open_connection {
    my $error;
    my $redis = try {
        Redis->new( server => "$SERVER:$SERVER_PORT", @$_PASSWORD );
    } catch {
        $error = $_;
    };
    BAIL_OUT( sprintf( '%s %sNot Redis%s',
            get_time_str(),
            $ATTEMPTS ? "($ATTEMPTS CHILD ATTEMPTS remaining) " : '',
            $error ? ": error = $error" : '',
        ) )
        unless _INSTANCE( $redis, 'Redis' );

    my $collection;
    $collection = try {
        Redis::CappedCollection->open(
            redis               => $redis,
            name                => $COLLECTION_NAME,
            reconnect_on_error  => 1,
        );
    } catch {
        $error = $_
    };
    BAIL_OUT( sprintf( '%s %sNot Redis::CappedCollection: error = %s',
            get_time_str(),
            $ATTEMPTS ? "($ATTEMPTS CHILD ATTEMPTS remaining) " : '',
            $error // '<undef>',
        ) )
        unless _INSTANCE( $collection, 'Redis::CappedCollection' );
    BAIL_OUT( sprintf( '%s %scollection unavailable',
            get_time_str(),
            $ATTEMPTS ? "($ATTEMPTS CHILD ATTEMPTS remaining) " : '',
        ) )
        unless $collection->ping;

    return $collection;
}

sub concurrent_forks_testing {
    my ( $collection ) = @_;

    unless ( $collection ) {
        my $error_msg;
        ( $error_msg, $collection ) = create_collection( $start_port );
        skip( $error_msg, 1 ) unless $collection;
        undef $collection;

        $collection = open_connection();
        ok $collection->ping, 'collection available';

        filling( $collection );
    }

    pass sprintf( '%s initial conditions: lua-time-limit = %d, concurent child = %d, concurrent forks = %d, concurent operations = %d',
        get_time_str(),
        $LUA_TIME_LIMIT,
        $CONCURENT_CHILD,
        $CONCURRENT_FORKS,
        $CONCURRENT_OPERATIONS,
    );
    my $info = get_collection_info( $collection );
    pass sprintf( '%s START: used_memory = %s, items = %s',
        get_time_str(),
        get_used_memory_str( $collection ),
        $info->{items} // '<undef>'
    );

    start_concurrent_children();
    wait_until_children();

    $info = get_collection_info( $collection );
    pass sprintf( '%s FINISH: used_memory = %s, items = %s',
        get_time_str(),
        get_used_memory_str( $collection ),
        $info->{items} // '<undef>'
    );
}

sub start_concurrent_children {
    my %concurrent_child_pids;
    $ATTEMPTS = $CONCURRENT_FORKS;
    while ( $ATTEMPTS )
    {
        if ( @CHILD_PIDS = keys %concurrent_child_pids ) {
            my $is_deleted;
            foreach my $pid ( @CHILD_PIDS ) {
                if ( waitpid( $pid, &WNOHANG ) ) {
                    delete $concurrent_child_pids{ $pid };
                    $is_deleted = 1;
                }
            }
            @CHILD_PIDS = keys %concurrent_child_pids if $is_deleted;
        }

        if ( scalar( @CHILD_PIDS ) < $CONCURENT_CHILD ) {
            my $child_pid = fork;
            if ( $child_pid ) {
                $concurrent_child_pids{$child_pid} = 1;
                say get_time_str()." remaining forks: $ATTEMPTS" unless $ATTEMPTS % 25_000;
                --$ATTEMPTS;
            } elsif ( defined $child_pid ) {
                my $ppid = getppid();
                concurent_child_work( $ppid );
                exit 0;
            } else {
                BAIL_OUT get_time_str().' An unexpected error (fork)';
            }
        }
#else {
#    say "wait... child pids: ".scalar( keys %concurrent_child_pids ).", remaining attempts = $ATTEMPTS";
#}
    }
}

my @operations = (
    \&insert_data,
    \&long_term_operation,
);

sub concurent_child_work {
    my ( $ppid ) = @_;

    my $collection  = open_connection();

    for ( 1 .. $CONCURRENT_OPERATIONS ){
        if ( $MAX_WORKING_CYCLES ) {
            my $operation_idx = int( rand( scalar( @operations ) ) );
            my $operation = $operations[ $operation_idx ];
            &$operation( $collection, $$, $ppid );
        } else {
            insert_data( $collection, $$, $ppid );
        }
    }
}

sub get_time_str {
    my $tm = Time::HiRes::time();
    my $localtime_str = scalar( localtime( int $tm ) );
    my @elements = $localtime_str =~ /^(\S+)\s+(\S+)\s+(\d+)\s+(\d\d:\d\d:\d\d)\s+(\d+)$/;
    my $ms = int( ( $tm - int( $tm ) ) * 1_000 );
    $elements[3] .= ".$ms"; # hh:mm:ss.$ms
    my $tm_str = sprintf( '%s %s %2s %s %s', @elements );

    return $tm_str;
}