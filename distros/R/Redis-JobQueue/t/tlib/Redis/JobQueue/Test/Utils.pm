package Redis::JobQueue::Test::Utils;

use 5.010;
use strict;
use warnings;

use Exporter qw(
    import
);
our @EXPORT_OK  = qw(
    get_redis
    verify_redis
);

use Net::EmptyPort;
use Test::More;
use Test::RedisServer;
use Try::Tiny;

use Redis::JobQueue qw(
    DEFAULT_SERVER
    DEFAULT_PORT
);

sub get_redis
{
    my @args = @_;

    my ( $redis, $error );
    for ( 1..3 )
    {
        try
        {
            $redis = Test::RedisServer->new( @args );
        }
        catch
        {
            $error = $_;
        };
        last unless $error;
        sleep 1;
    }

    return wantarray ? ( $redis, $error ) : $redis;
}

sub verify_redis
{
    my $redis;
    my $real_redis;
    my $skip_msg;
    my $port = Net::EmptyPort::empty_port( DEFAULT_PORT );

    $redis = get_redis( conf => { port => $port }, timeout => 3 );
    if ( $redis )
    {
        eval { $real_redis = Redis->new( server => DEFAULT_SERVER.":".$port ) };
        $skip_msg = "Redis server is unavailable" unless ( !$@ && $real_redis && $real_redis->ping );
        $skip_msg = "Need a Redis server version 2.8 or higher" if ( !$skip_msg && !eval { return $real_redis->eval( 'return 1', 0 ) } );
        $real_redis->quit if $real_redis;
    }
    else
    {
        $skip_msg = "Unable to create test Redis server";
    }

    return $redis, $skip_msg, $port;
}

1;
