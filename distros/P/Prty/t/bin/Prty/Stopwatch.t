#!/usr/bin/env perl

package Prty::Stopwatch::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Stopwatch');
}

# -----------------------------------------------------------------------------

sub test_unitTest_root: Test(1) {
    my $self = shift;

    my $stw = Prty::Stopwatch->new;
    sleep 1;
    my $duration = $stw->elapsed;
    # warn "$duration\n";
    $self->ok($duration >= 1 && $duration < 2);
}

# -----------------------------------------------------------------------------

package main;
Prty::Stopwatch::Test->runTests;

# eof
