#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;
use Test::LongString;

use Mojo::File qw(curfile);

use lib 'lib';
use lib '../lib';

## Webapp START

my $testdir = curfile->dirname->child( '..', 'test' );

plugin('Prove' => {
  tests => {
    base => $testdir,
  }
});

## Webapp END

my $t = Test::Mojo->new;

$t->get_ok( '/prove' )->status_is( 200 )->content_is( <<"HTML" );
<h2>Tests</h2>

<ul>
    <li><a href="/prove/test/base">base</a></li>
</ul>
HTML

$t->get_ok( '/prove/test/error/file/does_not_exist.t/run' )->status_is( 200 );
is_string $t->tx->res->body, <<"HTML";
<h2>Fehler</h2>
HTML

$t->get_ok( '/prove/test/base/file/does_not_exist.t/run' )->status_is( 200 );
is_string $t->tx->res->body, <<"HTML";
<h2>Fehler</h2>
HTML

$t->get_ok( '/prove/test/base/file//run' )->status_is( 200 );
is_string $t->tx->res->body, <<"HTML";
<h2>Fehler</h2>
HTML

done_testing();

