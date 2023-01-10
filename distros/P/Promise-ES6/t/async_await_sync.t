#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Config;
if ($Config{'config_args'} =~ m<DEBUGGING>) {
    plan skip_all => 'DEBUGGING perls confuse Future::AsyncAwait (as of 0.59, at least).';
}

# This test throws unhandled-rejection warnings … do they matter?
#use Test::FailWarnings;

my $failed_why;

BEGIN {
    eval 'use Test::Future::AsyncAwait::Awaitable; 1' or $failed_why = $@;
}

plan skip_all => "Can’t run test: $failed_why" if $failed_why;

use Promise::ES6;

Test::Future::AsyncAwait::Awaitable::test_awaitable(
    'Promise::ES6 conforms to Awaitable API',
    class => 'Promise::ES6',
    new => sub { Promise::ES6->new( sub {} ) },
);

done_testing;
