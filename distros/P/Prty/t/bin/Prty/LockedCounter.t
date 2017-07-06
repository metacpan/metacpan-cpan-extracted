#!/usr/bin/env perl

package Prty::LockedCounter::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::LockedCounter');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(6) {
    my $self = shift;

    my $file = "/tmp/test_counter$$";

    my $ctr = Prty::LockedCounter->new($file);
    $self->is($ctr->count,0);
    $ctr->increment;
    $self->is($ctr->count,1);
    $ctr->increment;
    $self->is($ctr->count,2);
    $ctr->increment;
    $self->is($ctr->count,3);

    $self->is($ctr->file,$file);

    my $data = Prty::Path->read($file);
    $self->is($data,"3\n");

    Prty::Path->delete($file);
}

# -----------------------------------------------------------------------------

package main;
Prty::LockedCounter::Test->runTests;

# eof
