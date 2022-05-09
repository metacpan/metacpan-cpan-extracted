#!/usr/bin/env perl

package Quiq::Shell::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Shell');
}

# -----------------------------------------------------------------------------

sub test_new : Test(1) {
    my $self = shift;

    my $sh = Quiq::Shell->new;
    $self->is(ref($sh),'Quiq::Shell');
}

# -----------------------------------------------------------------------------

sub test_exec : Test(2) {
    my $self = shift;

    eval {Quiq::Shell->exec('/bin/ls >/dev/null 2>&1')};
    $self->ok(!$@,'exec: Kommando erfolgreich');

    eval {Quiq::Shell->exec("/bin/not_a_command$$ >/dev/null 2>&1")};
    $self->like($@,qr/CMD-00002/,'exec: Kommando fehlgeschlagen');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Shell::Test->runTests;

# eof
