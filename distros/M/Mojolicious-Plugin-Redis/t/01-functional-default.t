#!/usr/bin/env perl
use strict;
use warnings;

# Disable IPv6, epoll and kqueue
BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More;

plan skip_all => 'set TEST_LIVE to enable this test'
  unless $ENV{TEST_LIVE};

plan tests => 6;

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;

my $server = $ENV{REDIS_SERVER} || 'localhost:6379';

plugin 'redis', { 
    'server' => $server
    };

get '/connection' => sub {
    my $self = shift;
    $self->render(text => ref($self->app->redis_connection));
};

get '/ping' => sub {
    my $self = shift;
    $self->render(text => $self->db->PING);
};


my $t = Test::Mojo->new;

$t->get_ok('/connection')->status_is(200)->content_is('Redis');
$t->get_ok('/ping')->status_is(200)->content_is('PONG');
