#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2015-2019 Joelle Maslak
# All Rights Reserved - See License
#

# This tests the Parallel::WorkUnit functionality in ordered mode

use strict;
use warnings;
use autodie;

use Carp;
use Test2::V0;

# Set Timeout
local $SIG{ALRM} = sub { die "timeout\n"; };
alarm 120;    # It would be nice if we did this a better way, since
              # strictly speaking, 120 seconds isn't necessarily
              # indicative of failure if running this on a VERY
              # slow machine.
              # But hopefully nobody has that slow of a machine!

# Instantiate the object
use Parallel::WorkUnit::Procedural qw(:all);

is( proc_count, 0, "no processes running before spawning any" );

my $wu;       # XXX

# We're going to spawn 10 children and test the return value
my $PROCS = 10;
for ( 0 .. $PROCS - 1 ) {
    async sub { return $_; };
    is( proc_count, 1 + $_, 1 + $_ . " workers are executing" );
}

my $r = waitone;
ok( defined($r), "waitone() returned a defined value" );
ok( ( $r >= 0 ) && ( $r < $PROCS ), "waitone() returned a valid return value" );
is( proc_count, $PROCS - 1, "waitone() properly reaped one process" );

my (@results) = waitall;

for ( 0 .. $PROCS - 1 ) {
    ok( exists( $results[$_] ), "Worker First Exec $_ returned properly" );
}
is( proc_count, 0, "no processes running after waitall()" );

# We're going to spawn 10 children at once with asyncs() and test the return value
$PROCS = 10;
asyncs( $PROCS, sub { return $_; } );
is( proc_count, $PROCS, "asyncs - $PROCS workers are executing" );

$r = waitone;
ok( defined($r), "asyncs - waitone() returned a defined value" );
ok( ( $r >= 0 ) && ( $r < $PROCS ), "asyncs - waitone() returned a valid return value" );
is( proc_count, $PROCS - 1, "asyncs - waitone() properly reaped one process" );

(@results) = waitall;

for ( 0 .. $PROCS - 1 ) {
    ok( exists( $results[$_] ), "asyncs - Worker First Exec $_ returned properly" );
}
is( proc_count, 0, "asyncs - no processes running after waitall()" );

# We make sure we can call this twice without issues
# So we're going to zero out the results and re-run the above
# test.

@results = ();

for ( 0 .. $PROCS - 1 ) {
    async sub { return $_ + 100 };
}

@results = waitall;

for ( 0 .. $PROCS - 1 ) {
    is( $results[$_], $_ + 100, "Worker Second Exec $_ returned properly" );
}

# We want to make sure that we can return a lot of data

queue sub { return 'BIG' x 500000; };

@results = waitall;

is( $results[0], 'BIG' x 500000, 'Result for big return callback as expected' );

# We want to test that we can return a more complex data type

async sub {
    my @ret;
    for ( my $i = 0; $i < 50000; $i++ ) { push @ret, $i; }
    return \@ret;
};

@results = waitall;

is( Scalar::Util::reftype( $results[0] ), 'ARRAY', 'Array reference properly returned' );

my @cmp;
for ( my $i = 0; $i < 50000; $i++ ) { push @cmp, $i; }

is( $results[0], \@cmp, 'Array reference contains proper values' );

# We want to test that we properly handle a child process that die()'s.

async sub { die "Error!"; };
ok dies { waitall }, 'Die when child throws an error';

# We want to test that we handle a process that returns undef properly

@results = ();
async sub { return; };
@results = waitall;

ok( exists( $results[0] ),   'Callback from undef returning fork called' );
ok( !defined( $results[0] ), 'Callback received undef from fork returning undef' );

# Finally we test "extra" wait's and waitall's don't hang

my $pid = async sub { return 'HERE'; };

proc_wait($pid);
proc_wait($pid);
pass("Duplicate wait() call exits properly");
waitall;
pass("Unnecessary waitall() call exits properly");
ok( !defined(waitone), 'Unnecessary waitone() call exits properly' );

# Do a test with the callback of async()
my $result;
async sub { 0 }, sub { $result = 555 };
waitall;
is( $result, 555, "Result from async() with callback" );

done_testing;
