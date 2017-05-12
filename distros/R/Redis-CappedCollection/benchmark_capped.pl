#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

use lib qw(
    lib
    t/tlib
);

# NAME: Redis::CappedCollection benchmark

use bytes;
use Carp;
use Time::HiRes     qw( gettimeofday );
use Redis '1.976';
use List::Util      qw( min sum );
use Getopt::Long    qw( GetOptions );
use Data::Dumper;

use Redis::CappedCollection qw(
    $DEFAULT_SERVER
    $DEFAULT_PORT
);

# ENVIRONMENT ------------------------------------------------------------------

#-- declarations ---------------------------------------------------------------

use constant {
    PORTION_TIME            => 10,
    INFO_TIME               => 60,
    VISITOR_ID_LEN          => 20,
    LOST_PRODUCTIVITY       => 3,               # allowable percentage of lost productivity
    };

my $host                    = $DEFAULT_SERVER;
my $port                    = $DEFAULT_PORT;
my $empty_port;
my $server;
my $redis;
my $max_size                = 512 * 1024 * 1024;    # 512MB
my $cleanup_bytes           = 0;
my $cleanup_items           = 0;
my $max_lists               = 2_000_000;
my $data_len                = 200;
my $run_time                = 0;
my $receive                 = 0;
my $dump                    = 0;

my %bench                   = ();
my $help                    = 0;
my $work_exit               = 0;
my $coll;
my $coll_name               = $$.'';
my $visitors                = 0;
my $rate                    = 0;

my $final_message           = 'The End!';

#-- setting up facilities

my $ret = GetOptions(
    'host=s'                    => \$host,
    'port=i'                    => \$port,
    'coll_name=s'               => \$coll_name,
    'max_size=i'                => \$max_size,
    'cleanup_bytes=i'           => \$cleanup_bytes,
    'cleanup_items=i'           => \$cleanup_items,
    'data_len=i'                => \$data_len,
    'visitors=i'                => \$max_lists,
    'run_time=i'                => \$run_time,
    'rate=f'                    => \$rate,
    'receive'                   => \$receive,
    'dump=i'                    => \$dump,
    "help|?"                    => \$help,
    );

if ( !$ret || $help )
{
    print <<'HELP';
Usage: $0 [--host="..."] [--port=...] [--coll_name="..."] [--max_size=...] [--cleanup_bytes=...] [--cleanup_items=...] [--data_len=...] [--visitors=...] [--run_time=...] [--rate=...] [--dump=...] [--receive] [--help]

Start a Redis client, connect to the Redis server, randomly inserts or receives data

Options:
    --help
        Display this help and exit.

    --host="..."
        The server should contain an IP address of Redis server.
        If not provided, '127.0.0.1' is used as the default.
    --port=N
        The server port.
        Default 6379 (the default for Redis server).
    --coll_name="..."
        Collection name.
        Default = process pid.
        To be used along with '--receive' option.
    --max_size=N
        The maximum size (bytes) of capped collection data volume.
        Default 512MB.
    --cleanup_bytes=N
        Size (bytes) of the data to be freed should size of the collection exceed 'max_size'.
        Default 0 - no advance cleanup performed.
    --cleanup_items=N
        Number of elements to be removed from collection during advance cleanup.
        Default 0 - no advance cleanup performed.
    --data_len=...
        Data unit size.
        Default 200 bytes.
    --visitors=N
        The number of lists to be created.
        Default 2_000_000.
    --run_time=...
        Maximum run time in seconds
        Default 0 - unlimited.
    --rate=N
        Exponentially distribute data using provided RATE.
        Default 0 - no exponental distribution.
    --dump=N
        Data dump volume.
        Default 0 - do not perform dump.
        WARNING: removes all keys from the current database.
    --receive
        Receive data instead of writing.
HELP
    exit 1;
}

my $item = '*' x $data_len;
my $upper = 0;
$upper = exponential( 0.99999 ) if $rate;
my $no_line = 0;

$| = 1;

#-- definition of the functions

$SIG{INT} = \&tsk;

sub tsk {
    $SIG{INT} = "IGNORE";
    $final_message = 'Execution is interrupted!';
    ++$work_exit;
    return;
}

sub client_info {
    my $redis_info = $redis->info;
    print "WARNING: Do not forget to manually delete the test data.\n";
    print '-' x 78, "\n";
    print "CLIENT INFO:\n",
        "server                 $server",                       "\n",
        "redis_version          $redis_info->{redis_version}",  "\n",
        "arch_bits              $redis_info->{arch_bits}",      "\n",
        "VISITOR_ID_LEN         ", VISITOR_ID_LEN,              "\n",
        "PORTION_TIME           ", PORTION_TIME,                "\n",
        "INFO_TIME              ", INFO_TIME,                   "\n",
        "coll_name              $coll_name",                    "\n",
        "data_len               $data_len",                     "\n",
        "maxmemory-policy       ", ( $redis->config_get( 'maxmemory-policy' ) )[1], "\n",
        "maxmemory              ", ( $redis->config_get( 'maxmemory' ) )[1],        "\n",
        "max_size               $max_size",                     "\n",
        "cleanup_bytes          $cleanup_bytes",                "\n",
        "cleanup_items          $cleanup_items",                "\n",
        "max_lists              $max_lists",                    "\n",
        "rate                   $rate",                         "\n",
        "dump                   $dump",                         "\n",
        "run_time               $run_time",                     "\n",
        '-' x 78,                                               "\n",
        ;
}

sub redis_info {
    my $redis_info = $redis->info;
    my $rss = $redis_info->{used_memory_rss};
    my $short_rss = ( $rss > 1024 * 1024 * 1024 ) ?
          $rss / ( 1024 * 1024 * 1024 )
        : $rss / ( 1024 * 1024 );
    my $info = $coll->collection_info;

    print
        "\n",
        '-' x 78,
        "\n",
        "data lists              $info->{lists}\n",
        "data items              $info->{items}\n",
        "mem_fragmentation_ratio $redis_info->{mem_fragmentation_ratio}\n",
        "used_memory_human       $redis_info->{used_memory_human}\n",
        "used_memory_rss         ", sprintf( "%.2f", $short_rss ), ( $rss > 1024 * 1024 * 1024 ) ? 'G' : 'M', "\n",
        "used_memory_peak_human  $redis_info->{used_memory_peak_human}\n",
        "used_memory_lua         $redis_info->{used_memory_lua}\n",
        "db0                     ", $redis_info->{db0} || "", "\n",
        '-' x 78,
        "\n",
        ;
}

# Send a request to Redis
sub call_redis {
    my $method      = shift;

    my @return = $redis->$method( @_ );

    return wantarray ? @return : $return[0];
}

sub exponential
{
    my $x = shift // rand;
    return log(1 - $x) / -$rate;
}

# Outputs random value in [0..LIMIT] range exponentially
# distributed with RATE. The higher is rate, the more skewed is
# the distribution (try rates from 0.1 to 3 to see how it changes).
sub get_exponentially_id {
# exponential distribution may theoretically produce big numbers
# (with low probability though) so we have to make an upper limit
# and treat all randoms greater than limit to be equal to it.

    my $r = exponential(); # exponentially distributed floating random
    $r = $upper if $r > $upper;
    return int( $r / $upper * ( $max_lists - 1 ) ); # convert to integer in (0..limit) range
}

sub measurement_info {
    my $measurement    = shift;

    print
        sprintf( "mean %.2f op/sec, mem %7s, rate has fallen by ",
            $measurement->{mean},
            $measurement->{used_memory},
            ),
        $measurement->{fallen} eq 'N/A' ? 'N/A' : sprintf( "%.2f%%", $measurement->{fallen} ),
        "\n";
}

sub _get_value {
    my $coll    = shift;
    my $key     = shift;
    my $type    = shift;

    return $coll->_call_redis( 'GET', $key )            if $type eq 'string';
    return $coll->_call_redis( 'LRANGE', $key, 0, -1 )  if $type eq 'list';
    return $coll->_call_redis( 'SMEMBERS', $key )       if $type eq 'set';

    if ( $type eq 'zset' ) {
        my %hash;
        my @zsets = $coll->_call_redis( 'ZRANGE', $key, 0, -1, 'WITHSCORES' );
        for ( my $loop = 0; $loop < scalar( @zsets ) / 2; $loop++ )
        {
            my $value = $zsets[ $loop * 2 ];
            my $score = $zsets[ ( $loop * 2 ) + 1 ];
            $hash{ $score } = $value;
        }
        return [ {%hash} ];
    }

    if ( $type eq 'hash' ) {
        my %hash;
        foreach my $item ( $coll->_call_redis( 'HKEYS', $key ) )
        {
            $hash{ $item } = $coll->_call_redis( 'HGET', $key, $item );
        }
        return {%hash};
    }
}

sub redis_dump {
    my $coll    = shift;

    my $redis_info = $redis->info;
    my %keys;

    printf( "used_memory %dB / %s\n", $redis_info->{used_memory}, $redis_info->{used_memory_human} );

    foreach my $key ( $coll->_call_redis( 'KEYS', '*' ) ) {
        my $type = $coll->_call_redis( 'TYPE', $key );
        my $show_name   = $key;
        my $encoding    = $coll->_call_redis( 'OBJECT', 'ENCODING', $key );
        my $refcount    = $coll->_call_redis( 'OBJECT', 'REFCOUNT', $key );
        $show_name     .= " ($type/$encoding: $refcount)";

        $keys{ $show_name } = _get_value( $coll, $key, $type );
    }
    return \%keys;
}

# INSTRUCTIONS -----------------------------------------------------------------

$server = "$host:$port";
$redis  = Redis->new( server => $server );
my $current_maxmemory_policy = ( $redis->config_get( 'maxmemory-policy' ) )[1];
my $current_maxmemory = ( $redis->config_get( 'maxmemory' ) )[1];

$redis->config_set( maxmemory => $max_size );
$redis->config_set( 'maxmemory-policy' => 'noeviction' );

$coll = Redis::CappedCollection->create(
    redis   => $redis,
    name    => $coll_name,
    $receive ? () : (
        cleanup_bytes   => $cleanup_bytes,
        cleanup_items   => $cleanup_items,
    ),
);

client_info();

if ( $receive and $coll_name eq $$.'' )
{
    print "There is no data to be read\n";
    goto THE_END;
}

my @measurements = ();

$redis->flushall if $dump;

my $measurement = {
    speed       => [],
    mean        => 0,
    fallen      => 0,
    used_memory => '',
    };

my $list_id;
my ( $secs, $count ) = ( 0, 0 );
my ( $time_before, $time_after );
my ( $start_time, $last_stats_reports_time, $last_info_reports_time );

my $data_id = 0;

$start_time = $last_stats_reports_time = $last_info_reports_time = time;
while ( !$work_exit )
{
    if ( $run_time ) { last if gettimeofday - $start_time > $run_time; }
    last if $work_exit;

    my $id          = ( !$receive && $rate ) ? get_exponentially_id() : int( rand $max_lists );
    $list_id        = sprintf( '%0'.VISITOR_ID_LEN.'d', $id );
    $time_before    = gettimeofday;
    my @ret         = $receive ? $coll->receive( $list_id ) : $coll->insert( $list_id, $data_id++, $item );
    $time_after     = gettimeofday;
    $secs += $time_after - $time_before;
    ++$count;

    if ( $dump and $count >= $dump )
    {
        my $dump = redis_dump( $coll );
        $Data::Dumper::Sortkeys = 1;
        print Dumper( $dump );
        goto THE_END;
    }

    my $redis_info = $redis->info;
    $measurement->{used_memory} = $redis_info->{used_memory_human},

    my $time_from_stats = $time_after - $last_stats_reports_time;
    if ( $time_from_stats > PORTION_TIME )
    {
        my $speed = int( $count / $secs );
        print '[', scalar localtime, '] ',
            $receive ? 'reads' : 'inserts', ', ',
            $secs ? sprintf( '%d', $speed ) : 'N/A', ' op/sec ',
            ' ' x 5, "\r";

        if ( gettimeofday - $last_info_reports_time > INFO_TIME )
        {
            redis_info();
            $last_info_reports_time = gettimeofday;
        }

        $secs  = 0;
        $count = 0;
        $last_stats_reports_time = gettimeofday;
    }
}

goto THE_FINISH if $work_exit;

# POSTCONDITIONS ---------------------------------------------------------------

THE_FINISH:

print
    "\n",
    $final_message,
    "\n",
    ;
THE_END:
$redis->config_set( maxmemory => $current_maxmemory );
$redis->config_set( 'maxmemory-policy' => $current_maxmemory_policy );
$redis->quit;

exit;
