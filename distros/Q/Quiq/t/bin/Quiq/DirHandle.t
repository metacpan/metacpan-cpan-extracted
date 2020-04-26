#!/usr/bin/env perl

package Quiq::DirHandle::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::DirHandle');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(1) {
    my $self = shift;

    my @arr;
    my $dh = Quiq::DirHandle->new('/tmp');
    while (my $entry = $dh->next) {
        push @arr,$entry;
    }
    $dh->close;

    $self->ok(@arr >= 2);
}

# -----------------------------------------------------------------------------

package main;
Quiq::DirHandle::Test->runTests;

# eof
