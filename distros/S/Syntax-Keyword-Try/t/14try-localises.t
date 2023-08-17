#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Keyword::Try;

# try/catch localises $@ (RT118415)
{
   eval { die "oopsie" };
   like( $@, qr/^oopsie at /, '$@ before try/catch' );

   try { die "another failure" } catch ($e) {}

   like( $@, qr/^oopsie at /, '$@ after try/catch' );
}

done_testing;
