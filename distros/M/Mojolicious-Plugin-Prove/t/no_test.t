#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;
use Test::LongString;

use Mojo::File qw(curfile);

use lib 'lib';
use lib '../lib';

## Webapp START

my $testdir = curfile->dirname->child( '..', 'test' )->to_string;

plugin('Prove' => {
  route  => app->routes,
  prefix => 'prove2',
});

## Webapp END

my $t = Test::Mojo->new;

$t->get_ok( '/prove2/test/base/run' )->status_is( 200 );

my $content = $t->tx->res->body;
like_string $content, qr'<h2>Fehler</h2>';

done_testing();

