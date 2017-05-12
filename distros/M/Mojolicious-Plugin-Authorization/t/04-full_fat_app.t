#!/usr/bin/env perl

use strict;
use warnings;

# testing in a "full fat" Mojolicious app, and also that we can
# return status codes other than the default 404 not found when
# users lack privs/roles

package FullFatAuth;

use Mojo::Base qw( Mojolicious );

sub startup {
  my ( $self ) = @_;

  $self->plugin(
    'authorization' => {
      has_priv    => sub { 0 },
      is_role     => sub { 0 },
      user_privs  => sub { {} },
      user_role   => sub { undef },
      fail_render => { status => 401, json => { error => 'Denied' } },
    }
  );

  $self->routes->any('/cake/make')
    ->over(has_priv => 'cake:eat')
    ->to('Public#eat_cake')
  ;

  $self->routes->any('/cake/eat')
    ->over(is_role => 'chef')
    ->to('Public#make_cake')
  ;
}

package FullFatAuth::Public;

use Mojo::Base 'Mojolicious::Controller';

package main;

use strict;
use warnings;

use Test::Mojo;
use Test::More;
use Test::Deep;
use Mojolicious::Commands;

my $t = Test::Mojo->new( 'FullFatAuth' );

$t->get_ok( '/cake/make' )->status_is( 401 );

cmp_deeply(
  $t->tx->res->json,
  { error => 'Denied' },
  'has_priv failure renders custom response',
);

$t->get_ok( '/cake/eat' )->status_is( 401 );

cmp_deeply(
  $t->tx->res->json,
  { error => 'Denied' },
  'is_role failure renders custom response',
);

done_testing();

# vim: ts=2:sw=2:et
