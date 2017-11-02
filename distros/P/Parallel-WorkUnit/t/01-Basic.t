#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2015 Joelle Maslak
# All Rights Reserved - See License
#

# This tests the Parallel::WorkUnit functionality

use strict;
use warnings;
use autodie;

use Carp;
use Test::More tests => 50;
use Test::Exception;

# Set Timeout
local $SIG{ALRM} = sub { die "timeout\n"; };
alarm 120; # It would be nice if we did this a better way, since
           # strictly speaking, 120 seconds isn't necessarily
           # indicative of failure if running this on a VERY
           # slow machine.
           # But hopefully nobody has that slow of a machine!

# Instantiate the object
require_ok('Parallel::WorkUnit');
my $wu = Parallel::WorkUnit->new();
ok(defined($wu), "Constructer returned object");
is($wu->count, 0, "no processes running before spawning any");

# We're going to spawn 10 children and test the return value
my %RESULTS;
my $PROCS = 10;
for ( 0 .. $PROCS-1 ) {
    $wu->async(
        sub { return $_; },
        \&cb
    );
    is($wu->count, 1+$_, 1+$_ . " workers are executing");
}

my $r = $wu->waitone();
ok(defined($r), "waitone() returned a defined value");
ok( ($r >= 0) && ($r < $PROCS), "waitone() returned a valid return value");
is($wu->count, $PROCS-1, "waitone() properly reaped one process");

$wu->waitall();

for ( 0 .. $PROCS-1 ) {
    ok(exists($RESULTS{$_}), "Worker First Exec $_ returned properly");
}
is($wu->count, 0, "no processes running after waitall()");


# We make sure we can call this twice without issues
# So we're going to zero out the results and re-run the above
# test.

%RESULTS = ();

for ( 0 .. $PROCS-1 ) {
    $wu->async(
        sub { return $_ + 100; },
        \&cb
    );
}

$wu->waitall();

for ( 0 .. $PROCS-1 ) {
    ok(exists($RESULTS{$_ + 100}), "Worker Second Exec $_ returned properly");
}


# We want to make sure that we can return a lot of data

$wu->async(
    sub { return 'BIG'x500000; },
    \&cb_big
);

$wu->waitall();

ok(exists($RESULTS{BIG}), 'Callback for big return called');
is($RESULTS{BIG}, 'BIG'x500000, 'Result for big return callback as expected');


# We want to test that we can return a more complex data type

$wu->async(
    sub { 
        my @ret;
        for (my $i=0; $i<50000; $i++) { push @ret, $i; }
        return \@ret;
    },
    \&cb_big
);

$wu->waitall();

ok(exists($RESULTS{BIG}), 'Callback for array ref return called');
is(Scalar::Util::reftype($RESULTS{BIG}), 'ARRAY', 'Array reference properly returned');

my @cmp;
for (my $i=0; $i<50000; $i++) { push @cmp, $i; }

is_deeply($RESULTS{BIG}, \@cmp, 'Array reference contains proper values');


# We want to test that we properly handle a child process that die()'s.

$wu->async(
    sub { die "Error!"; },
    sub { return; }
);
dies_ok { $wu->waitall(); } 'Die when child throws an error';


# We want to test that we handle a process that returns undef properly

%RESULTS = ();
$wu->async(
    sub { return; },
    \&cb_big
);
$wu->waitall();

ok(exists($RESULTS{BIG}), 'Callback from undef returning fork called');
ok(!defined($RESULTS{BIG}), 'Callback received undef from fork returning undef');


# Finally we test "extra" wait's and waitall's don't hang

my $pid = $wu->async(
    sub { return 'HERE'; },
    \&cb
);

ok(!exists($RESULTS{HERE}), 'Callback for single process wait not called');
$wu->wait($pid);
ok(exists($RESULTS{HERE}), 'Callback for single process wait called');
$wu->wait($pid);
pass("Duplicate wait() call exits properly");
$wu->waitall();
pass("Unnecessary waitall() call exits properly");
ok(!defined($wu->waitone()), 'Unnecessary waitone() call exits properly');


# The below subs are the callbacks

sub cb {
    $RESULTS{$_[0]} = 1;
}

sub cb_big {
    $RESULTS{BIG} = $_[0];
}
