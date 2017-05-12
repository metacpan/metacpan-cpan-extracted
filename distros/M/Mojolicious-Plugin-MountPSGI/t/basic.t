#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More tests => 4;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'MountPSGI', { '/' => 't/script/basic.psgi' };


my $t = Test::Mojo->new;
$t->get_ok('/foo', {'X-Extra-Header' => 'ok'})
  ->status_is(200)
  ->header_is('X-Extra-Reply' => 'ok')
  ->content_is("hello, world\n");
