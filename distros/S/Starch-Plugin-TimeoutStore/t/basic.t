#!/usr/bin/env perl
use strictures 2;

use Test2::V0;
use Test::Starch;
use Starch;

Test::Starch->new(
    plugins => ['::TimeoutStore'],
)->test();

{
    package Starch::Store::Test::TimeoutStore;
    use Moo;
    with 'Starch::Store';
    sub set { _sleep_one() }
    sub get { _sleep_one() }
    sub remove { _sleep_one() }
    sub _sleep_one {
        my $start = time();
        while (1) {
            last if time() > $start + 1;
        }
        return;
    }
}

my $timeout_starch = Starch->new(
    plugins => ['::TimeoutStore'],
    store => { class=>'::Test::TimeoutStore', timeout=>1 },
);
my $timeout_store = $timeout_starch->store();

my $normal_starch = Starch->new(
    plugins => ['::TimeoutStore'],
    store => { class=>'::Test::TimeoutStore' },
);
my $normal_store = $normal_starch->store();

foreach my $method (qw( set get remove )) {
    is(
        dies { $normal_store->$method() },
        undef,
        "no timeout when calling $method",
    );

    like(
        dies { $timeout_store->$method() },
        qr{timeout},
        "timeout when calling $method",
    );
}

done_testing;
