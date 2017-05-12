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
our (
    $_SERVER_ADDRESS,
    $_COLLECTION_NAME,
    $_WORK_MODE,
    $_PASSWORD,
    $STUFF_LENGTH,
    $MAX_DATA_SIZE,
    $MAX_LIST_LENGTH,
);
my (
    $MAXMEMORY,
    $DEBUG,
    $DEFAULT_ITEMS,
    $LIST_ITERATIONS,
    $OPERATIONS,
);

#NOTE: $MAXMEMORY below value used only when test without script arguments
$MAXMEMORY          = 70 * 1024 * 1024; # minimum for remote server 'maxmemory'
$DEBUG              = 1;        # logging: $DEBUG > 0 for 'used_memory > maxmemory' waiting, 2 and 3 for operation durations logging

$OPERATIONS         = 3;
$LIST_ITERATIONS    = 10;
$STUFF_LENGTH       //= 200;
$DEFAULT_ITEMS      = 25_000;
$MAX_DATA_SIZE      //= $STUFF_LENGTH * $DEFAULT_ITEMS;

BEGIN {
    use Getopt::Long qw(
        GetOptions
    );

    my $help;

    my $ret = GetOptions(
        'server:s'          => \$_SERVER_ADDRESS,
        'collection:s'      => \$_COLLECTION_NAME,
        'mode:s'            => \$_WORK_MODE,
        'password:s'        => \$_PASSWORD,
        'stuff-length:s'    => \$STUFF_LENGTH,
        'max-data-size:s'   => \$MAX_DATA_SIZE,
        'max-list-length:s' => \$MAX_LIST_LENGTH,
        "help|?"            => \$help,
    );

    if ( $help ) {
        say <<"HELP";
Usage: $0 [--server="..."] [--collection=...] [--mode="..."] [--password="..."] [--stuff-length="..."] [--max-data-size="..."] [--max-list-length="..."] [--help]

Open existing Redis::CappedCollection collection, dump collection data content.

Options:
    --help
        Display this help and exit.

    --server="..."
        The server should contain an IP_address:port of Redis server.
    --collection="..."
        The collection name.
    --mode="..."
        'create'    - connect to 'server' and create empty 'collection'.
        'connect'   - connect to 'server', clear and tests on existing 'collection'.
        'max-info'  - connect to 'server', get information about max length list and max length data.
        Redis server must be started manually before in both cases.
    --password="..."
        If your Redis server requires authentication, you can use the password argument.
    --stuff-length="..."
        The size of a recorded data item.
    --max-data-size="..."
        The maximum size of the data that are recorded in the collection.
    --max-list-length="..."
        The maximum items in the list.

    All or none of arguments must be present.

    Example redis server command string:
        ./redis-server --maxmemory-policy noeviction --maxmemory 512mb

    Example script command strings:
        $0 --server 127.0.0.1:6379 --collection SomeCollection --mode create
        $0 --server 127.0.0.1:6379 --collection SomeCollection --mode connect
        $0 --server 127.0.0.1:6379 --collection SomeCollection --mode max-info
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
            unless $_WORK_MODE eq 'create' || $_WORK_MODE eq 'connect' || $_WORK_MODE eq 'max-info'
        ;
    } elsif ( $_SERVER_ADDRESS || $_COLLECTION_NAME || $_WORK_MODE ) {
        BAIL_OUT( 'wrong script arguments' );
    }

    BAIL_OUT( "'max-data-size' or 'max-list-length' may be specified" )
        unless !defined( $MAX_DATA_SIZE ) || !defined( $MAX_LIST_LENGTH );

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
    max
);
use Params::Util qw(
    _INSTANCE
);
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

$Redis::CappedCollection::DEBUG = $DEBUG;

my $max_data_size_available = $MAXMEMORY * ( 1 - $Redis::CappedCollection::MIN_MEMORY_RESERVE );
BAIL_OUT( "Too big max data size $MAX_DATA_SIZE, may be up to $max_data_size_available" )
    if $MAX_DATA_SIZE > $max_data_size_available;

#-- data variables
my $LIST_ID         = 'Some list_id';
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
my @DATA_IDS;

my ( $REDIS_SERVER, $error_msg, $start_port, $collection );

if ( $_SERVER_ADDRESS ) {
    if ( $_WORK_MODE eq 'create' ) {
        $collection = create_remote_collection();
        exit;
    } elsif ( $_WORK_MODE eq 'connect' ) {
        $collection = connect_remote_collection();
    } elsif ( $_WORK_MODE eq 'max-info' ) {
        connect_remote_collection( 1 );
        exit;
    }
} else {
    ( $REDIS_SERVER, $error_msg, $start_port ) = verify_redis( $_PASSWORD ? $_PASSWORD->[1] : undef );
    BAIL_OUT $error_msg if $error_msg;

    $collection = create_collection( $start_port );
}

if ( $collection ) {
    pass sprintf( '%s initial conditions: DEBUG = %d, maxmemory = %s, max data size = %db (%s)',
        get_time_str(),
        $DEBUG // 0,
        sprintf( '%0.2fmb', $MAXMEMORY / ( 1024 * 1024 ) ),
        $MAX_DATA_SIZE,
        sprintf( '%0.2fmb', $MAX_DATA_SIZE / ( 1024 * 1024 ) ),
    );

    testing( $collection );     # receive all values from list
    testing( $collection, 1 );  # single data_receive
}

exit;

#-------------------------------------------------------------------------------

sub connect_remote_collection {
    my ( $need_max_info ) = @_;

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

    verify_server_maxmemory( $collection );

    if ( $need_max_info ) {
        my $items = get_collection_info( $collection )->{items};

        my ( $longest_list, $longest_data ) = get_max_list_info( $collection );
        pass sprintf( "%s collection '%s' on '%s': items = %s\n\tlongest list: id = '%s', items = %d\n\tlongest data: list id = '%s', data id = '%s', data length = %d",
            get_time_str(),
            $COLLECTION_NAME,
            $_SERVER_ADDRESS,
            $items,
            $longest_list->{list_id},
            $longest_list->{items},
            $longest_data->{list_id},
            $longest_data->{data_id},
            $longest_data->{data_length},
        );

        return;
    }

    $collection->clear_collection;

    my $items = get_collection_info( $collection )->{items};

    pass sprintf( "%s collection '%s' on '%s': items = %s",
        get_time_str(),
        $COLLECTION_NAME,
        $_SERVER_ADDRESS,
        $items,
    );

    return $collection;
}

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
            older_allowed       => 1,
            reconnect_on_error  => 1,
        );
    }
    BAIL_OUT( get_time_str().' Cannot connect to redis server' ) unless $collection;
    isa_ok( $collection, 'Redis::CappedCollection' );
    ok $collection->ping, 'collection available';

    verify_server_maxmemory( $collection );

    $collection->clear_collection;

    my $items = get_collection_info( $collection )->{items};

    pass sprintf( "%s collection '%s' on '%s': items = %s",
        get_time_str(),
        $COLLECTION_NAME,
        $_SERVER_ADDRESS,
        $items,
    );

    return $collection;
}

sub testing {
    my ( $collection, $single_data_receive ) = @_;

    $collection = open_connection();
    ok $collection->ping, 'collection available';
    return unless $collection;

    $MAX_LIST_LENGTH //= int( $MAX_DATA_SIZE / $STUFF_LENGTH );
    pass sprintf( '%s RECEIVE MODE: %s, max iterations = %d, stuff length = %db, max list length = %d',
        get_time_str(),
        $single_data_receive
            ? 'single data receive'
            : 'receive all values (data) from list',
        $LIST_ITERATIONS,
        $STUFF_LENGTH,
        $MAX_LIST_LENGTH,
    );

    my $list_lengths = get_lengths( $LIST_ITERATIONS );
    my $i = 1;
    my $iterations = scalar @$list_lengths;
    foreach my $list_length ( @$list_lengths ) {
        my $stuff = fill_collection( $collection, $STUFF_LENGTH, $list_length );
        my $max_duration = test_collection( $collection, $stuff, $single_data_receive );
        pass sprintf( '%s iteration %d/%d: list length = %d, max duration = %.3f sec',
            get_time_str(),
            $i,
            $iterations,
            $list_length,
            $max_duration,
        );

        unless ( $single_data_receive ) {
            my $full_list;
            ( $max_duration, $full_list ) = test_full_list( $collection );
            my $full_data_length = 0;
            $full_data_length += length( $_ ) foreach @$full_list;
            my %list = ( @$full_list );
            my $list_length = scalar( keys %list );
            my $real_list_length = $collection->list_info( $LIST_ID )->{items};
            BAIL_OUT "Error in list length calculation: $list_length != $real_list_length" unless $list_length == $real_list_length;
            pass sprintf( "\treceive full list: list length = %d, full data length = %d, max duration = %.3f sec",
                $list_length,
                $full_data_length,
                $max_duration,
            );
        }

        ++$i;
    }
}

sub test_full_list {
    my ( $collection ) = @_;

    my ( @durations, $tm_start, $tm_finish, @data );
    for ( my $i = 1; $i <= $OPERATIONS; ++$i ) {
        @data = ();
        try {
            $tm_start = Time::HiRes::time();
            @data = $collection->receive( $LIST_ID, '' );   # '' for receive all data (keys and values)
            $tm_finish = Time::HiRes::time();
        } catch {
            my $error = $_;
            BAIL_OUT get_time_str()." BAD full list receive: $error";
        };
        BAIL_OUT( get_time_str()." full list receive: BAD - received empty data list" )
            unless @data;

        # WARN: because redis lua-memory may be corrupted
        Redis::CappedCollection::_clear_sha1( $collection->_redis );

        push @durations, $tm_finish - $tm_start;
        say "$i/$OPERATIONS" unless $i % 5_000;
    }

    my $max_duration = max( @durations );
    return( $max_duration, \@data );
}

sub test_collection {
    my ( $collection, $stuff, $single_data_receive ) = @_;

    my ( @durations, $tm_start, $tm_finish );
    for ( my $i = 1; $i <= $OPERATIONS; ++$i ) {
        if ( $single_data_receive ) {
            my $data_id = $DATA_IDS[ int( rand scalar @DATA_IDS ) ];
            my $data;
            try {
                $tm_start = Time::HiRes::time();
                $data = $collection->receive( $LIST_ID, $data_id ); # receive single data
                $tm_finish = Time::HiRes::time();
            } catch {
                my $error = $_;
                BAIL_OUT get_time_str()." BAD receive: $error";
            };
            BAIL_OUT( get_time_str()." receive: BAD received data (received = '".( $data // '<undef>' )."')" )
                unless $data && $data eq $stuff;
        } else {
            my @data;
            try {
                $tm_start = Time::HiRes::time();
                @data = $collection->receive( $LIST_ID );   # receive only values
                $tm_finish = Time::HiRes::time();
            } catch {
                my $error = $_;
                BAIL_OUT get_time_str()." BAD receive: $error";
            };
            BAIL_OUT( get_time_str()." receive: BAD - received empty data list" )
                unless @data;

            # WARN: because redis lua-memory may be corrupted
            Redis::CappedCollection::_clear_sha1( $collection->_redis );
        }

        push @durations, $tm_finish - $tm_start;
        say "$i/$OPERATIONS" unless $i % 5_000;
    }

    my $max_duration = max( @durations );
    return $max_duration;
}

sub fill_collection {
    my ( $collection, $stuff_length, $list_length ) = @_;

    $collection->clear_collection;
    @DATA_IDS = ();

    my $stuff = get_stuff();
    for ( 1 .. $list_length ) {
        my $data_time   = Time::HiRes::time();
        my $data_id     = $data_time;
        my $result = try {
            $collection->upsert( $LIST_ID, $data_id, $stuff, $data_time );
        } catch {
            my $error = $_;
            BAIL_OUT( get_time_str()."BAD upsert: $error" );
        };
        BAIL_OUT( 'upsert: Cannot insert into collection' ) unless $result;

        my $info = get_collection_info( $collection );
        BAIL_OUT( "collection overflowed: stuff length = $stuff_length, list length = $list_length, maxmemory = $MAXMEMORY" )
            if %$info && $info->{last_removed_time}; # cleaning executed

        push @DATA_IDS, $data_id;
    }

    return $stuff;
}

sub get_lengths {
    my ( $iterations ) = @_;

    my @lengths;

    for ( my $i = 1; $i <= $iterations; ++$i ) {
        my $iterations = $i == $iterations
            ? $MAX_LIST_LENGTH
            : int( $i * $MAX_LIST_LENGTH / $iterations )
        ;
        next unless $iterations;

        push @lengths, $iterations;
    }

    @lengths = uniq_nums( @lengths );

    return \@lengths;
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

sub create_collection {
    my ( $port ) = @_;

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
            $_PASSWORD ? ( requirepass => $_PASSWORD->[1] ) : (),
        },
    );
    BAIL_OUT $error_msg unless $REDIS_SERVER;
    isa_ok( $REDIS_SERVER, 'Test::RedisServer' );
    say 'Redis server tmpdir: '.$REDIS_SERVER->tmpdir;

    my $collection = Redis::CappedCollection->create(
        redis               => $REDIS_SERVER,
        name                => $COLLECTION_NAME,
        older_allowed       => 1,
        reconnect_on_error  => 1,
    );
    isa_ok( $collection, 'Redis::CappedCollection' );
    ok $collection->ping, 'collection available';

    my $redis = $collection->_redis;
    isa_ok( $redis, 'Redis' );
    ok $redis->ping, 'redis server available';

    return $collection;
}

sub open_connection {
    my $error;
    my $redis = try {
        Redis->new( server => "$SERVER:$SERVER_PORT", @$_PASSWORD );
    } catch {
        $error = $_;
    };
    BAIL_OUT( sprintf( '%s %s',
            get_time_str(),
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
    BAIL_OUT( sprintf( '%s Not Redis::CappedCollection: error = %s',
            get_time_str(),
            $error // '<undef>',
        ) )
        unless _INSTANCE( $collection, 'Redis::CappedCollection' );
    BAIL_OUT( sprintf( '%s %scollection unavailable',
            get_time_str(),
        ) )
        unless $collection->ping;

    return $collection;
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

sub get_stuff {
    return '*' x $STUFF_LENGTH;
}

sub get_max_list_info {
    my ( $collection ) = @_;

    my ( %longest_list, %longest_data );
    my $count = 0;
    foreach my $list_id ( $collection->lists( '*' ) ) {
        my $items = $collection->list_info( $list_id )->{items};
        %longest_list = (
            list_id => $list_id,
            items   => $items,
        ) if $items > ( $longest_list{items} // 0 );
        my %all_data = ( $collection->receive( $list_id, '' ) );    # '' for receive all data (keys and values)
        while ( my ( $data_id, $data) = each %all_data ) {
            my $data_length = length $data;
            %longest_data = (
                list_id     => $list_id,
                data_id     => $data_id,
                data_length => $data_length,
            ) if $data_length > ( $longest_data{data_length} // 0 );

            ++$count;
            say "$count items processed" unless $count % 100_000;
        }
    }

    return( \%longest_list, \%longest_data );
}

sub uniq_nums {
    my ( @nums ) = @_;

    my %uniq_nums;
    $uniq_nums{ $_ } = 1 foreach @nums;
    return( sort { $a <=> $b } keys %uniq_nums );
}

sub verify_server_maxmemory {
    my ( $collection ) = @_;

    my $server_maxmemory = $collection->_redis->info( 'memory' )->{maxmemory} // 0;

    BAIL_OUT sprintf( "Too small server 'maxmemory': required = %d, on server = %d",
        $MAXMEMORY,
        $server_maxmemory,
    ) if $server_maxmemory && $server_maxmemory < $MAXMEMORY;
}
