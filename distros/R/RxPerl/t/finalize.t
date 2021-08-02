#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use RxPerl::Test;

use RxPerl::SyncTimers ':all';

subtest 'with unsubscribe' => sub {
    my @test;
    my $s; $s = rx_interval(1)->pipe(
        op_finalize(sub { push @test, 'f1' }),
        op_finalize(sub { push @test, 'f2' }),
    )->subscribe(sub {
        $s->unsubscribe;
    });

    RxPerl::SyncTimers->start;

    is \@test, ['f1', 'f2'], 'right events in right order';
};

subtest 'with complete' => sub {
    my @test;
    my $s; $s = rx_interval(1)->pipe(
        op_take(3),
        op_finalize(sub { push @test, 'f1' }),
        op_finalize(sub { push @test, 'f2' }),
    )->subscribe({
        complete => sub { push @test, 'c' },
    });

    RxPerl::SyncTimers->start;

    is \@test, ['c', 'f1', 'f2'], 'right events in right order';
};

subtest 'with take at the end' => sub {
    my @test;
    my $s; $s = rx_interval(1)->pipe(
        op_finalize(sub { push @test, 'f1' }),
        op_finalize(sub { push @test, 'f2' }),
        op_take(3),
    )->subscribe({
        complete => sub { push @test, 'c' },
    });

    RxPerl::SyncTimers->start;

    is \@test, ['c', 'f1', 'f2'], 'right events in right order';
};

subtest 'with error' => sub {
    my @test;
    my $s; $s = rx_throw_error('foo')->pipe(
        op_finalize(sub { push @test, 'f1' }),
        op_finalize(sub { push @test, 'f2' }),
    )->subscribe(
        sub {},
        sub { push @test, 'e' },
    );

    RxPerl::SyncTimers->start;

    is \@test, ['e', 'f1', 'f2'], 'right events in right order';
};

done_testing;
