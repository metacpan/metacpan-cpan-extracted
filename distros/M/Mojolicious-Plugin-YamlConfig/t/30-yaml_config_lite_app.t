#!/usr/bin/env perl

# Copyright (C) 2008-2010, Sebastian Riedel.
# Copyright (C) 2010, Danijel Tasov.

use strict;
use warnings;

use utf8;

# Disable epoll, kqueue and IPv6
BEGIN { $ENV{MOJO_POLL} = $ENV{MOJO_NO_IPV6} = 1 }

use Mojo::IOLoop;
use Test::More;
use Mojolicious;

# Make sure sockets are working
plan tests => 12;

# Oh, I always feared he might run off like this.
# Why, why, why didn't I break his legs?
use Mojolicious::Lite;
use Test::Mojo;

# Silence
app->log->level('error');

# Load plugin
my $config =
  plugin yaml_config => {default => {foo => 'baz', hello => 'there'}};
is($config->{foo},   'bar',    'right value');
is($config->{hello}, 'there',  'right value');
is($config->{utf},   'утф',    'right value');
is($config->{bar}, 2, 'rendering');

SKIP: {
    eval 'require YAML::XS; 1' ||
        skip 'YAML::XS required for this test', 3;

    my $config = plugin yaml_config => {
        default => {foo => 'baz', hello => 'there'},
        class => "YAML::XS",
    };

    is($config->{foo},   'bar',    'right value');
    is($config->{hello}, 'there',  'right value');
    is($config->{utf},   'утф',    'right value');
};

# GET /
get '/' => 'index';

my $t = Test::Mojo->new;

# GET /
$t->get_ok('/')->status_is(200)->content_like(qr/bar/, 'right content');

# No config file, default only
$config =
  plugin yaml_config => {file => 'nonexisted', default => {foo => 'qux'}};
is($config->{foo}, 'qux', 'right value');

# No config file, no default
ok(! eval { plugin yaml_config => {file => 'nonexisted'} }, 'no config file');

__DATA__
@@ index.html.ep
<%= $config->{foo} %>
