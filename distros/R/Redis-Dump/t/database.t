#!perl

use warnings;
use strict;
use Test::More;
use Test::Exception;
use Test::Deep;
use IO::String;
use Redis;
use Redis::Dump;

use lib 't/tlib';
use Test::SpawnRedisServer;

my ( $c, $srv ) = redis();
END { $c->() if $c }

ok( my $r = Redis->new( server => $srv ), 'connected to our test redis-server' );

$r->select(0);
$r->set( foo        => 1 );

$r->select(1);
$r->set( bar        => 2 );

ok( my $dump = Redis::Dump->new( { server => $srv, database => 1 } ), 'run redis-dump' );
is_deeply( { $dump->run }, { 'bar' => '2' } );

done_testing();
