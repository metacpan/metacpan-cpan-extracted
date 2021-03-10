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
  tests => {
    base => $testdir,
  },
  route  => app->routes,
  prefix => 'prove2',
});

## Webapp END

my $t = Test::Mojo->new;

$t->get_ok( '/prove2/test/base/run?format=text' )->status_is( 200 );

my $content = $t->tx->res->body;
like_string $content, qr!01_success.t .. ok!;
like_string $content, qr!02_fail.t ..... \s+Dubious, test returned 1 \(wstat 256, 0x100\)\s+Failed 1/1 subtests!;
like_string $content, qr!Test Summary Report\s+-------------------\s+.*?02_fail.t .*\s+  Failed test:  1\s+  Non-zero exit status: 1\s+Files=2, Tests=2, .*\s+Result: FAIL!;

done_testing();

