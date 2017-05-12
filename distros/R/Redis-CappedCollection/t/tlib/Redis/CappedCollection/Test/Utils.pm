package Redis::CappedCollection::Test::Utils;

use 5.010;
use strict;
use warnings;

use Exporter qw(
    import
);
our @EXPORT_OK  = qw(
    clear_coll_data
    get_redis
    verify_redis
);

use Net::EmptyPort;
use Test::More;
use Test::RedisServer;
use Try::Tiny;

use Redis::CappedCollection qw(
    $DEFAULT_SERVER
    $DEFAULT_PORT
    $NAMESPACE
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
    my ( $password ) = @_;

    my $redis;
    my $real_redis;
    my $skip_msg;
    my $port = Net::EmptyPort::empty_port( $DEFAULT_PORT );

    $redis = get_redis(
        conf    => {
            port                => $port,
            'maxmemory-policy'  => 'noeviction',
            $password ? ( requirepass => $password ) : (),
        },
        timeout => 3,
    );
    if ( $redis )
    {
        eval {
            $real_redis = Redis->new(
                server => $DEFAULT_SERVER.":".$port,
                $password ? ( password => $password ) : (),
            )
        };
        $skip_msg = "Redis server is unavailable" unless ( !$@ && $real_redis && $real_redis->ping );
        $skip_msg = "Need a Redis server version 2.8 or higher" if ( !$skip_msg && !eval { return $real_redis->eval( 'return 1', 0 ) } );
        unless ( $skip_msg ) {
            $real_redis->script_flush;
            $real_redis->quit;
        }
    }
    else
    {
        $skip_msg = "Unable to create test Redis server";
    }

    return $redis, $skip_msg, $port;
}

sub clear_coll_data {
    my ( $coll ) = @_;

    eval { $coll->_call_redis( 'DEL', $NAMESPACE.':Q:'.$coll->name ); };
    eval { $coll->_call_redis( 'DEL', $NAMESPACE.':S:'.$coll->name ); };
    eval { $coll->_call_redis( 'DEL', $coll->_call_redis( 'KEYS', $NAMESPACE.':I:'.$coll->name.":*" ) ); };
    eval { $coll->_call_redis( 'DEL', $coll->_call_redis( 'KEYS', $NAMESPACE.':D:'.$coll->name.":*" ) ); };
    eval { $coll->_call_redis( 'DEL', $coll->_call_redis( 'KEYS', $NAMESPACE.':T:'.$coll->name.":*" ) ); };
}

1;
