#!/usr/bin/env perl
use strict;
use warnings;
use Redis;
use Test::RedisServer;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
 
my $redis_server;
my $redis;
eval {
    $redis_server = Test::RedisServer->new;
    $redis = Redis->new( $redis_server->connect_info );
    $redis->ping;
} or plan skip_all => 'redis-server is required to this test';
 
plugin 'resque', { redis => $redis };

get '/push' => sub {
    my $self = shift;
    $self->resque( test_queue => { class => 'Test', args => [ 'test' ] } );
    $self->render( text => 'done' );
};

get '/pop' => sub {
    my $self = shift;
    my $job = $self->resque->pop('test_queue');
    $self->render( text => $job->class );
};

my $t = Test::Mojo->new;

$t->get_ok('/push')->status_is(200)->content_is('done');
$t->get_ok('/pop')->status_is(200)->content_is('Test');

done_testing;
