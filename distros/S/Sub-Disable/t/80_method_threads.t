use strict;
our $have_threads;
BEGIN {
    $have_threads = eval{require threads; threads->create(sub{return 1})->join};
}
use Test::More ($have_threads) ? ('no_plan') : (skip_all => 'for threaded perls only');

use Sub::Disable 'foo';

my $test = 1;

sub foo {$test = 2}
sub bar {$test = 3}

eval 'main->foo';
is $test, 1;

threads->create(sub{
    eval 'main->foo';
    is $test, 1;

    Sub::Disable->import('bar');
    eval 'main->bar';
    is $test, 1;

    eval 'main->foo';
    is $test, 1;

    threads->create(sub{
        eval 'main->bar';
        is $test, 1;
    })->join;

    return 1;
})->join;

eval 'main->bar';
is $test, 3;
