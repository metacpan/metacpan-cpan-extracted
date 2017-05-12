#!/usr/bin/env perl
use strict;
use warnings;

# Disable IPv6, epoll and kqueue
BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More;
use Try::Tiny;

plan tests => 3;

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;

my $server = $ENV{REDIS_SERVER} || 'localhost:6379';

plugin 'redis', { 
    'server' => $server,
    'nohelper'  => 1
    };

get '/test' => sub {
    my $self = shift;
    my $rv = 0;

    try {
        my $foo = $self->db;
    } catch {
        $rv = 1;
    };
    $self->render(text => ($rv == 1) ? 'ok' : 'fail');
};


my $t = Test::Mojo->new;

$t->get_ok('/test')->status_is(200)->content_is('ok');