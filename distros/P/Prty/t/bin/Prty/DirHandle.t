#!/usr/bin/env perl

package Prty::DirHandle::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::DirHandle');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(1) {
    my $self = shift;

    my @arr;
    my $dh = Prty::DirHandle->new('/tmp');
    while (my $entry = $dh->next) {
        push @arr,$entry;
    }
    $dh->close;

    $self->ok(@arr > 2);
}

# -----------------------------------------------------------------------------

package main;
Prty::DirHandle::Test->runTests;

# eof
