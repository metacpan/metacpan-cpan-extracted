#!/usr/bin/env perl
package ChiTest;
use base qw(CHI);

package main;
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use File::Temp qw/:POSIX tempdir/;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::CHI';

my $t = Test::Mojo->new;
my $app = $t->app;

my $c = Mojolicious::Controller->new;
$c->app($app);

my $path = tempdir(CLEANUP => 1);

$app->plugin(CHI => {
  MyCache2 => {
    driver => 'File',
    root_dir => $path
  },
  namespaces => 1,
  chi_class => 'ChiTest',
});

Mojo::IOLoop->start;

my $my_cache = $c->chi('MyCache2');
is($my_cache->chi_root_class, "ChiTest", 'use ChiTest as my root class');

done_testing;
