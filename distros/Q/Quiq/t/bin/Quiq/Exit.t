#!/usr/bin/env perl

package Quiq::Exit::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Exit');
}

# -----------------------------------------------------------------------------

sub test_check : Test(2) {
    my $self = shift;

    # system('/no/cmd 4711'); # FIXME: Ausgabe auf STDERR unterdrücken
    # eval { Quiq::Exit->check($?,$!) };
    # $self->like($@,qr/CMD-00001/,
    #     'check: Kommando konnte nicht gestartet werden';

    system('true'); # Fix: CPAN Testers
    eval { Quiq::Exit->check($?) };
    $self->ok(!$@,'check: Kommando erfolgreich ausgeführt');

    system('false'); # Fix: CPAN Testers
    eval { Quiq::Exit->check($?) };
    $self->like($@,qr/CMD-00002/,'check: Kommando endete mit Fehler');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Exit::Test->runTests;

# eof
