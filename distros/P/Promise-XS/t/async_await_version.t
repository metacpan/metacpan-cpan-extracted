#!/usr/bin/env perl

use strict;
use warnings;

# This test exists for no reason other than to ensure that CPAN Testers
# always shows the Future::AsyncAwait version.

use Test::More;

use Promise::XS;

# This test throws unhandled-rejection warnings … do they matter?
#use Test::FailWarnings;

my $failed_why;

BEGIN {
    eval 'use Test::Future::AsyncAwait::Awaitable; 1' or $failed_why = $@;
}

plan skip_all => "Can’t run test: $failed_why" if $failed_why;

require Future::AsyncAwait;
diag "Future::AsyncAwait $Future::AsyncAwait::VERSION";

ok 1;

done_testing;
