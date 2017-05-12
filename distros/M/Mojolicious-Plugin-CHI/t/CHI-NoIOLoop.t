#!/usr/bin/env perl
use Mojolicious::Lite;
use Test::More tests => 17;
use Test::Mojo;
use File::Temp qw/:POSIX tempdir/;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::CHI';

my $t = Test::Mojo->new;
my $app = $t->app;

my $hash1 = {};
my $hash2 = {};

$app->plugin(Config => {
  default => {
    CHI => {
      default => {
        driver => 'Memory',
	datastore => $hash1
      }
    }
  }
});

$app->plugin('CHI' => {
  MyCache => {
    driver => 'Memory',
    datastore => $hash2
  }
});

my $c = Mojolicious::Controller->new;
$c->app($app);

my $my_cache = $c->chi('MyCache');
ok($my_cache, 'CHI handle');

ok($my_cache->set(key_1 => 'Wert 1'), 'Wert 1');
ok($my_cache->set(key_2 => 'Wert 2'), 'Wert 2');
ok($my_cache->set(key_3 => 'Wert 3'), 'Wert 3');

is($my_cache->get('key_1'), 'Wert 1', 'Wert 1');
is($my_cache->get('key_2'), 'Wert 2', 'Wert 2');
is($my_cache->get('key_3'), 'Wert 3', 'Wert 3');

ok(!$c->chi->get('key_1'), 'No value');
ok(!$c->chi->get('key_2'), 'No value');
ok(!$c->chi->get('key_3'), 'No value');

ok($c->chi->set('key_1' => '-Wert 1'), '-Wert1');
ok($c->chi->set('key_2' => '-Wert 2'), '-Wert2');
ok($c->chi->set('key_3' => '-Wert 3'), '-Wert3');

is($c->chi->get('key_1'), '-Wert 1', '-Wert 1');
is($c->chi->get('key_2'), '-Wert 2', '-Wert 2');
is($c->chi->get('key_3'), '-Wert 3', '-Wert 3');
