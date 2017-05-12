#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Mojolicious::Plugin::Restify;

my @tests = (
  [['foo-bar']             => {'foo-bar' => undef}],
  [['foo-bar/bar-bar']     => {'foo-bar' => {'bar-bar' => undef}}],
  [['foo-bar/bar-bar/baz'] => {'foo-bar' => {'bar-bar' => {'baz' => undef}}}],
  [['users/roles/messages'] => {'users' => {'roles' => {'messages' => undef}}}],
  [
    ['foo-bar', 'foo-bar/bar-bar', 'invoices'] =>
      {'foo-bar' => {'bar-bar' => undef}, 'invoices' => undef}
  ],
  [
    [
      'foo-bar', 'foo-bar/bar-bar',
      ['messages' => {over => 'uuid'}], 'invoices',
      'users', 'users/roles',
      'users/messages'
    ] => {
      'foo-bar'  => {'bar-bar' => undef},
      'invoices' => undef,
      'messages' => [undef, {over => 'uuid'}],
      'users' => {'roles' => undef, 'messages' => undef},
    }
  ]
);

is_deeply Mojolicious::Plugin::Restify::_arrayref_to_hashref(undef), {};
is_deeply Mojolicious::Plugin::Restify::_arrayref_to_hashref([]),    {};

for my $test (@tests) {
  my ($array, $hash) = ($test->[0], $test->[1]);
  my $coerce = Mojolicious::Plugin::Restify::_arrayref_to_hashref($array);
}

done_testing;
