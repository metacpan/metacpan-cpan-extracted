#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More tests => 3;

use Mojolicious::Lite;
use Test::Mojo;

my $app = sub {
    return [200, ['Content-Type' => 'text/plain'], ["hello, world\n"]];
};

plugin 'MountPSGI', { '/' => $app };


my $t = Test::Mojo->new;
$t->get_ok('/foo')->status_is(200)->content_is("hello, world\n");
