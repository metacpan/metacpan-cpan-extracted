#!perl

use warnings;
use strict;
use Test::More;
use Test::Exception;
use Test::Deep;
use Redis;
use Redis::Dump;
use JSON;
use File::Temp qw/ tempfile /;
use Redis::Dump::Restore;

use lib 't/tlib';
use Test::SpawnRedisServer;

my ( $c, $srv ) = redis();
END { $c->() if $c }

my ( $fh, $filename ) = tempfile();

if ( !-r $filename ) {
    Test::More::plan skip_all => "Could not read the tempfile: $filename";
    return;
}

ok( my $r = Redis->new( server => $srv ), 'connected to our test redis-server' );

$r->set( foo => 1 );
$r->hset( 'mhash', 'f1', 1 );
$r->rpush( 'mlist', 1 );
$r->sadd( 'slist', 2 );
$r->zadd( 'zlist', 1, 'foo' );

ok( my $dump = Redis::Dump->new( { server => $srv } ), 'run redis-dump' );

my $old_db = { $dump->run };
print $fh to_json($old_db);
close($fh);

ok( my $restore = Redis::Dump::Restore->new(
        {   server   => $srv,
            file     => $filename,
            flushall => 1
        }
    )
);

ok( $r = Redis->new( server => $srv ), 'connected to our test redis-server' );
ok( $dump = Redis::Dump->new( { server => $srv } ), 'run redis-dump' );
my $new_db = { $dump->run };

is_deeply( $old_db, $new_db );

done_testing();
