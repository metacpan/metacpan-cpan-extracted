#!/usr/bin/env perl 
use strict;
use warnings;

use Test::More;

use Syntax::Keyword::Dynamically;
use Syntax::Keyword::Try;
use Future::AsyncAwait;
use IO::Async::Loop;

our $TRACE;

my $loop = IO::Async::Loop->new;

my $pending = $loop->new_future;
(async sub {
    my ($f) = @_;
    try {
        dynamically $TRACE = 'async sub';
        is($TRACE, 'async sub');
        await $f;
        is($TRACE, 'async sub');
    } catch {
        fail('exception - ' . $@);
    }
})->($pending);

done_testing;
