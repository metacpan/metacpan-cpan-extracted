#!/usr/bin/env perl

package Quiq::Parallel::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Parallel');
}

# -----------------------------------------------------------------------------

sub test_runArray : Test(1) {
    my $self = shift;

    $| = 1;
    Quiq::Parallel->runArray([1..10],sub {
        my ($elem,$i) = @_;
        sleep 1;
        return;
    });
    $self->ok(1);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Parallel::Test->runTests;

# eof
