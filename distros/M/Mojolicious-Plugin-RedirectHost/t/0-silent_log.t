#!/usr/bin/env perl
package Mojolicious::Plugin::RedirectHost::MockLog;
use Mojo::Base -base;
has error => 'unchanged';

package main;
use Mojo::Base -strict;
use Test::More tests => 1;

use Mojolicious::Lite;

app->log(Mojolicious::Plugin::RedirectHost::MockLog->new());
plugin 'RedirectHost', {silent => 1};
is app->log->error, 'unchanged', 'i am silent';


