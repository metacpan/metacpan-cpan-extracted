#!/usr/bin/env perl
use lib qw(t lib ../lib ../mojo/lib ../../mojo/lib);
use utf8;

use Test::More tests => 1;

require_ok( 'Mojolicious::Plugin::UserMessages' );
