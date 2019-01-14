#!/usr/bin/env perl

package Quiq::LockedCounter::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::LockedCounter');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(6) {
    my $self = shift;

    my $file = "/tmp/test_counter$$";

    my $ctr = Quiq::LockedCounter->new($file);
    $self->is($ctr->count,0);
    $ctr->increment;
    $self->is($ctr->count,1);
    $ctr->increment;
    $self->is($ctr->count,2);
    $ctr->increment;
    $self->is($ctr->count,3);

    $self->is($ctr->file,$file);

    my $data = Quiq::Path->read($file);
    $self->is($data,"3\n");

    Quiq::Path->delete($file);
}

# -----------------------------------------------------------------------------

package main;
Quiq::LockedCounter::Test->runTests;

# eof
