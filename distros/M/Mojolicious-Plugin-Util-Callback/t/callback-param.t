#!/usr/bin/env perl
package Mojolicious::Plugin::TestForCallback;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($plugin, $mojo, $param) = @_;

  unless (exists $mojo->renderer->helpers->{callback}) {
    $mojo->plugin('Util::Callback');
  };

  $mojo->helper(
    test_helper => sub {
      return 'Hi!';
    });

  $mojo->helper(
    test_helper_2 => sub {
      return shift->callback('test_cb');
    }
  );
};

package Mojolicious::Plugin::TestForCallback2;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($plugin, $mojo, $param) = @_;

  unless (exists $mojo->renderer->helpers->{callback}) {
    $mojo->plugin('Util::Callback');
  };

  # Establish callbacks
  $mojo->callback(
    ['test_cb_2', 'test_cb_3'] => $param
  );

  $mojo->callback(
    ['test_cb_4'] => $param, -once
  );

  $mojo->helper(
    test_helper_3 => sub {
      return shift->callback('test_cb_2');
    });

  $mojo->helper(
    test_helper_4 => sub {
      return shift->callback('test_cb_3');
    }
  );
};

package main;
use Mojolicious::Lite;

use lib '../lib';

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;
my $app = $t->app;

ok($app->plugin('TestForCallback'), 'Use Callback Plugin');

is($app->test_helper, 'Hi!', 'TestHelper works');
ok($app->callback(test_cb => sub { 'yeah' }), 'TestHelper works');
is($app->test_helper_2, 'yeah', 'TestHelper works');

$app->plugin(TestForCallback2 => {
  test_cb_2 => sub { 'yeah 2' },
  test_cb_3 => sub {
    my $c = shift;
    return $c->test_helper . ' + yeah 3'
  }
});

ok($app->callback('test_cb_4' => sub { 'Fine' }), 'Establish callback');

is($app->test_helper_3, 'yeah 2', 'TestHelper works');
is($app->test_helper_4, 'Hi! + yeah 3', 'TestHelper works');
ok($app->callback(test_cb_3 => sub { shift->test_helper_2 . ' + yeah 4' }), 'Redefine test helper');
is($app->test_helper_4, 'yeah + yeah 4', 'TestHelper works');

is($app->callback('test_cb_4'), 'Fine', 'Establish callback');

ok(!$app->callback('test_cb_4' => sub { 'Not fine!' }), 'Establish callback');

done_testing;
