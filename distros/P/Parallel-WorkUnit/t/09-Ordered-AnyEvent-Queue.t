#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2015-2018 Joelle Maslak
# All Rights Reserved - See License
#

# This tests the Parallel::WorkUnit queue functionality with AnyEvent
# using ordered queuing.

use strict;
use warnings;
use autodie;

use Carp;
use Test::More tests => 140;
use Test::Exception;

SKIP: {
    if ( !eval { require AnyEvent } ) {
        skip 'AnyEvent not installed', 144;
    }

    # Set Timeout
    local $SIG{ALRM} = sub { die "timeout\n"; };
    alarm 120;    # It would be nice if we did this a better way, since
                  # strictly speaking, 120 seconds isn't necessarily
                  # indicative of failure if running this on a VERY
                  # slow machine.
                  # But hopefully nobody has that slow of a machine!

    # Instantiate the object
    require_ok('Parallel::WorkUnit');
    my $wu = Parallel::WorkUnit->new();
    $wu->use_anyevent(1);

    ok( defined($wu), "Constructer returned object" );
    is( $wu->count, 0, "no processes running before spawning any" );

    dies_ok { $wu->max_children(-1); } 'Die when set max children to -1';
    dies_ok { $wu->max_children(0); } 'Die when set max children to 0';
    dies_ok { $wu->max_children('abc'); } 'Die when set max children to non-int';

    is( $wu->max_children(), 5, 'Max children defaults to 5' );

    lives_ok { $wu->max_children(10) } 'Max children set to 10';
    is( $wu->max_children(), 10, 'Max children is 10' );

    lives_ok { $wu->max_children(2) } 'Max children set to 2';
    is( $wu->max_children(), 2, 'Max children defaults to 2' );

    # We're going to spawn 10 children and test the return value, just to
    # make sure it queue() works basically like async().
    my $PROCS = 10;
    for ( 0 .. $PROCS - 1 ) {
        my $v = $_;
        my $ret = $wu->queue( sub { return $v; } );

        if ( $_ <= 1 ) {
            ok( $ret, "Worker " . ( 1 + $_ ) . " started" );
            is( $wu->count, 1 + $_, ( 1 + $_ ) . " workers are executing" );
        } else {
            ok( !$ret, "Worker " . ( 1 + $_ ) . " queued" );
            is( $wu->count, 2, "2 workers of " . ( 1 + $_ ) . " are executing" );
        }
    }

    my $r = $wu->waitone();
    ok( defined($r), "waitone() returned a defined value" );
    ok( ( $r >= 0 ) && ( $r < $PROCS ), "waitone() returned a valid return value" );
    is( $wu->count, 2, "waitone() properly kept two processes running" );

    my (@results) = $wu->waitall();

    for ( 0 .. $PROCS - 1 ) {
        is( $results[$_], $_, "Worker First Exec $_ returned properly" );
    }
    is( $wu->count, 0, "no processes running after waitall()" );

    # We're going to spawn 10 children and test the return value, just to
    # make sure it queue() works basically like async().  This time, though,
    # we are testing with an unlimited max_children
    lives_ok { $wu->max_children(undef) } 'Max children set to undef';
    is( $wu->max_children(), undef, 'Max children defaults to undef' );

    $PROCS = 10;
    for ( 0 .. $PROCS - 1 ) {
        my $v = $_;
        my $ret = $wu->queue( sub { return $v; } );

        ok( $ret, "(W1) Worker " . ( 1 + $_ ) . " started" );
        is( $wu->count, 1 + $_, "(W1) " . ( 1 + $_ ) . " workers are executing" );
    }

    $r = $wu->waitone();
    ok( defined($r), "waitone() returned a defined value" );
    ok( ( $r >= 0 ) && ( $r < $PROCS ), "waitone() returned a valid return value" );
    is( $wu->count, 9, "waitone() properly kept nine processes running" );

    @results = $wu->waitall();

    for ( 0 .. $PROCS - 1 ) {
        is( $results[$_], $_, "Worker First Exec $_ returned properly" );
    }
    is( $wu->count, 0, "no processes running after waitall()" );

    lives_ok { $wu->max_children(2) } 'Max children set to 2';
    is( $wu->max_children(), 2, 'Max children defaults to 2' );

    # Queue up 10 processes
    for ( 0 .. $PROCS - 1 ) {
        my $v = $_;
        my $ret = $wu->queue( sub { return $v; } );

        if ( $_ <= 1 ) {
            ok( $ret, "(W2) Worker " . ( 1 + $_ ) . " started" );
            is( $wu->count, 1 + $_, "(W2) " . ( 1 + $_ ) . " workers are executing" );
        } else {
            ok( !$ret, "(W2) Worker " . ( 1 + $_ ) . " queued" );
            is( $wu->count, 2, "(W2) 2 workers of " . ( 1 + $_ ) . " are executing" );
        }
    }

    $r = $wu->waitone();
    ok( defined($r), "(W2) waitone() returned a defined value" );
    ok( ( $r >= 0 ) && ( $r < $PROCS ), "(W2) waitone() returned a valid return value" );
    is( $wu->count, 2, "(W2) waitone() properly kept two processes running" );

    # Decrease max children, shouldn't kill anything
    $wu->max_children(1);
    is( $wu->count, 2, "(W2) waitone() properly still kept two processes running" );
    $wu->waitone();
    is( $wu->count, 1, "(W2) waitone() properly kept one running" );

    # Increase max children
    $wu->max_children(3);
    is( $wu->count, 3, "(W2) waitone() properly kept three processes running" );
    $wu->max_children(30);
    is( $wu->count, 8, "(W2) waitone() properly kept nine processes running" );

    @results = $wu->waitall();

    for ( 0 .. $PROCS - 1 ) {
        is( $results[$_], $_, "(W2) Worker First Exec $_ returned properly" );
    }
    is( $wu->count, 0, "(W2) no processes running after waitall()" );

    # We make sure we can call this twice without issues
    # So we're going to zero out the results and re-run the above
    # test.

    for ( 0 .. $PROCS - 1 ) {
        my $v = $_;
        $wu->queue( sub { return $v + 100; } );
    }

    @results = $wu->waitall();

    for ( 0 .. $PROCS - 1 ) {
        is( $results[$_], $_ + 100, "Worker Second Exec $_ returned properly" );
    }

    # We want to make sure that we can return a lot of data

    $wu->queue( sub { return 'BIG' x 500000; } );

    @results = $wu->waitall();

    is( $results[0], 'BIG' x 500000, 'Result for big return callback as expected' );

    # We want to test that we can return a more complex data type

    $wu->queue(
        sub {
            my @ret;
            for ( my $i = 0; $i < 50000; $i++ ) { push @ret, $i; }
            return \@ret;
        }
    );

    @results = $wu->waitall();

    is( Scalar::Util::reftype( $results[0] ), 'ARRAY', 'Array reference properly returned' );

    my @cmp;
    for ( my $i = 0; $i < 50000; $i++ ) { push @cmp, $i; }

    is_deeply( $results[0], \@cmp, 'Array reference contains proper values' );

    # We want to test that we properly handle a child process that die()'s.

    $wu->queue( sub { die "Error!"; } );
    dies_ok { $wu->waitall(); } 'Die when child throws an error';

    # We want to test that we handle a process that returns undef properly

    $wu->queue( sub { return; } );
    @results = $wu->waitall();

    ok( exists( $results[0] ),   'Callback from undef returning fork called' );
    ok( !defined( $results[0] ), 'Callback received undef from fork returning undef' );

    # Finally we test "extra" wait's and waitall's don't hang

    $wu->queue( sub { return 'HERE'; } );

    $wu->waitone();
    $wu->waitone();
    pass("Duplicate waitone() call exits properly");
    $wu->waitall();
    pass("Unnecessary waitall() call exits properly");
    ok( !defined( $wu->waitone() ), 'Unnecessary waitone() call exits properly' );
}

