#!/usr/bin/env perl

package Quiq::Stopwatch::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Stopwatch');
}

# -----------------------------------------------------------------------------

sub test_unitTest_root: Test(1) {
    my $self = shift;

    my $stw = Quiq::Stopwatch->new;
    sleep 1;
    my $duration = $stw->elapsed;
    $self->ok($duration > 0.5 && $duration < 1.5);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Stopwatch::Test->runTests;

# eof
