#!/usr/bin/env perl
use strict;
use warnings;

use lib '../lib';

use Test::More;
use Test::Mojo;

use Mojolicious::Lite;

my $t = Test::Mojo->new;
my $app = $t->app;

ok($app->plugin('Util::Callback'), 'Use Callback Plugin');

my $c = Mojolicious::Controller->new;
$c->app($app);

my %cache = (
  Akron => 30,
  Peter => 31,
  Jan   => 32
);

ok($app->callback(
  from_cache => sub {
    my $c = shift;
    my $name = shift;
    return $cache{$name};
  }), 'Establish callback');

is($c->callback(from_cache => 'Akron'), 30, 'Call callback');
is($c->callback(from_cache => 'Peter'), 31, 'Call callback');
is($c->callback(from_cache => 'Jan'), 32, 'Call callback');

ok($app->callback(
  from_cache => sub {
    my $c = shift;
    my $name = shift;
    return 'is ' . $cache{$name};
  }, -once), 'Establish callback');

is($c->callback(from_cache => 'Akron'), 'is 30', 'Call callback');
is($c->callback(from_cache => 'Peter'), 'is 31', 'Call callback');
is($c->callback(from_cache => 'Jan'), 'is 32', 'Call callback');

ok(!$app->callback(
  from_cache => sub {
    my $c = shift;
    my $name = shift;
    return 'was ' . $cache{$name};
  }, -once), 'Establish callback');

is($c->callback(from_cache => 'Akron'), 'is 30', 'Call callback');
is($c->callback(from_cache => 'Peter'), 'is 31', 'Call callback');
is($c->callback(from_cache => 'Jan'), 'is 32', 'Call callback');
ok(!$c->callback(from_supercache => 'Jan'), 'Call callback');


done_testing;
