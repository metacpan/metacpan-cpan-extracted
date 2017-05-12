#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More tests => 3;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'MountPSGI', { '/' => 't/script/streaming.psgi' };


my $t = Test::Mojo->new;
$t->get_ok('/foo')->status_is(200)->content_is("hello, world\n");
