#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Promise::XS;

# This test throws unhandled-rejection warnings … do they matter?
#use Test::FailWarnings;

my $failed_why;

BEGIN {
    eval 'use Test::Future::AsyncAwait::Awaitable; 1' or $failed_why = $@;
}

plan skip_all => "Can’t run test: $failed_why" if $failed_why;

Test::Future::AsyncAwait::Awaitable::test_awaitable(
    'Conforms to Awaitable API',
    class => 'Promise::XS::Promise',
    new => sub { Promise::XS::deferred()->promise() },
);

done_testing;
