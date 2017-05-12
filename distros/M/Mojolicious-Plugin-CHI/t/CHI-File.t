#!/usr/bin/env perl
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
  namespaces => 1
});

Mojo::IOLoop->start;

my $my_cache = $c->chi('MyCache2');
ok($my_cache, 'CHI handle');
ok($my_cache->set(key_1 => 'Wert 1'), 'Wert 1');
is($my_cache->get('key_1'), 'Wert 1', 'Wert 1');

opendir(D, $path);
my @test = readdir(D);
closedir(D);

ok(join(',', @test) =~ m/MyCache2/, 'Namespace option valid');

# Test with new namespace default

$t = Test::Mojo->new;
$app = $t->app;

$c = Mojolicious::Controller->new;
$c->app($app);

$path = tempdir(CLEANUP => 1);

$app->plugin(CHI => {
  MyCache3 => {
    driver => 'File',
    root_dir => $path
  }
});

Mojo::IOLoop->start;

$my_cache = $c->chi('MyCache3');
ok($my_cache, 'CHI handle');
ok($my_cache->set(key_1 => 'Wert 1'), 'Wert 1');
is($my_cache->get('key_1'), 'Wert 1', 'Wert 1');

if (opendir(D, $path)) {
  @test = readdir(D);
  closedir(D);
  pass('Read cache dir');
}

else {
  fail('Unable to read cache dir');
};

ok(join(',', @test) =~ m/MyCache3/, 'Namespace option valid');

# Test with off namespace

$t = Test::Mojo->new;
$app = $t->app;

$c = Mojolicious::Controller->new;
$c->app($app);

$path = tempdir(CLEANUP => 1);

$app->plugin(CHI => {
  MyCache4 => {
    driver => 'File',
    root_dir => $path
  },
  namespaces => 0
});

Mojo::IOLoop->start;

$my_cache = $c->chi('MyCache4');
ok($my_cache, 'CHI handle');
ok($my_cache->set(key_1 => 'Wert 1'), 'Wert 1');
is($my_cache->get('key_1'), 'Wert 1', 'Wert 1');

my %hash;
opendir(D, $path);
$hash{$_} = 1 foreach readdir(D);
closedir(D);


# Default namespace
ok($hash{'Default'}, 'Namespace option valid');

done_testing;
