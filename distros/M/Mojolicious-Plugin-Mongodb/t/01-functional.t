#!/usr/bin/env perl
use strict;
use warnings;

# Disable IPv6, epoll and kqueue
BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More;

if(!$ENV{TEST_MONGODB}) {
    plan skip_all => 'Please set the TEST_MONGODB variable to a MongoDB connection string (host:port) in order to test';
} else {
    plan tests => 24;
}

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;

my ($host, $port) = split(/:/, $ENV{TEST_MONGODB});
$host ||= 'localhost';
$port ||= 27017;

my $dbname = 'mojolicious_plugin_mongodb_test_' . $$;
my $dbname2 = 'mojolicious_plugin_mongodb_test_2' . $$;

plugin 'mongodb', { 
    'host'      => $host,
    'port'      => $port,
    'database'  => $dbname,
    'helper'    => 'foo',
    };

get '/connection' => sub {
    my $self = shift;
    $self->render(text => ref($self->app->mongodb_connection));
};

get '/getdb' => sub {
    my $self = shift;
    $self->render(text => $self->foo($dbname)->name);
};

get '/getotherdb' => sub {
    my $self = shift;
    $self->render(text => $self->foo($dbname2)->name);
};

get '/lastdb' => sub {
    my $self = shift;
    $self->render(text => $self->foo->name);
};

get '/db-get-collection/:cname' => sub {
    my $self = shift;
    my $cname = $self->stash('cname');
    $self->render(text => $self->foo->get_collection($cname)->name);
};

get '/db-coll/:cname' => sub {
    my $self = shift;
    my $cname = $self->stash('cname');
    $self->render(text => $self->coll($cname)->name);
};

get '/db-coll-full/:cname' => sub {
    my $self = shift;
    my $cname = $self->stash('cname');
    $self->render(text => $self->coll($cname, $dbname2)->full_name);
};

get '/model/:modelname' => sub {
    my $self = shift;
    my $model = $self->stash('modelname');
    $self->render(text => $self->model($dbname2 . '.' . $model)->full_name);
};

my $t = Test::Mojo->new;

$t->get_ok('/connection')->status_is(200)->content_is('MongoDB::Connection');
$t->get_ok('/getdb')->status_is(200)->content_is($dbname);
$t->get_ok('/getotherdb')->status_is(200)->content_is($dbname2);
$t->get_ok('/lastdb')->status_is(200)->content_is($dbname2);
$t->get_ok('/db-get-collection/test1')->status_is(200)->content_is('test1');
$t->get_ok('/db-coll/test1')->status_is(200)->content_is('test1');
$t->get_ok('/db-coll-full/test1')->status_is(200)->content_is("$dbname2.test1");
$t->get_ok('/model/testmodel')->status_is(200)->content_is("$dbname2.testmodel");
