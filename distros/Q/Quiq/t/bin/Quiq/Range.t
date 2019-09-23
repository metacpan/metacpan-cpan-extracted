#!/usr/bin/env perl

package Quiq::Range::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Range');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(3) {
    my $self = shift;

    my $rng = Quiq::Range->new('');
    $self->is(ref($rng),'Quiq::Range');

    my @arr = $rng->numbers;
    $self->isDeeply(\@arr,[],'Leerer Range ist leere Liste');

    @arr = Quiq::Range->numbers('3,5,7-10,16,81-85,101');
    $self->isDeeply(\@arr,[3,5,7,8,9,10,16,81,82,83,84,85,101]);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Range::Test->runTests;

# eof
