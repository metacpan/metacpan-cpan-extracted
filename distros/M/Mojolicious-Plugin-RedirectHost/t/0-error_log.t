#!/usr/bin/env perl
package Mojolicious::Plugin::RedirectHost::MockLog;
use Mojo::Base -base;
has error => '';

package main;
use Mojo::Base -strict;
use Test::More tests => 1;

use Mojolicious::Lite;

app->log(Mojolicious::Plugin::RedirectHost::MockLog->new());
plugin 'RedirectHost';
like app->log->error, qr/define/, 'error logging';


