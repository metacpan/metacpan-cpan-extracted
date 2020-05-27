#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '9999';

use Test::More;
use Test::PerlTidy;

if ( !$ENV{AUTHOR_TESTING} ) {
    plan skip_all => 'these tests are for testing by the author';
}

run_tests( exclude =>
      [ 'Makefile.PL', '.build/', 'blib', qr{xt/author/(?!perltidy[.]t$)}mxs, ], );
