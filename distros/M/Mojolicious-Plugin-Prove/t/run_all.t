#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;
use Test::LongString;

use File::Spec;
use File::Basename;

use lib 'lib';
use lib '../lib';

## Webapp START

my $testdir = File::Spec->catdir( dirname(__FILE__), '..', 'test' );

plugin('Prove' => {
  tests => {
    base => $testdir,
  }
});

## Webapp END

my $t = Test::Mojo->new;

$t->get_ok( '/prove/test/base/run' )->status_is( 200 );

my $content = $t->tx->res->body;
my $regex   = qr!t/../test/01_success.t .. ok
t/../test/02_fail.t ..... 
Dubious, test returned 1 \(wstat 256, 0x100\)
Failed 1/1 subtests 

Test Summary Report
-------------------
t/../test/02_fail.t .*
  Failed test:  1
  Non-zero exit status: 1
Files=2, Tests=2, .*
Result: FAIL!;

like_string $content, $regex;
if ( $content !~ $regex ) {
  diag $content;
}

done_testing();

