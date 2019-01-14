#!/usr/bin/env perl

package Quiq::Shell::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

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

sub test_checkError : Test(2) {
    my $self = shift;

    # system('/no/cmd 4711'); # FIXME: Ausgabe auf STDERR unterdrücken
    # eval { Quiq::Shell->checkError($?,$!) };
    # $self->like($@,qr/CMD-00001/,
    #     'checkError: Kommando konnte nicht gestartet werden';

    system('true'); # Fix: CPAN Testers
    eval { Quiq::Shell->checkError($?,$!) };
    $self->ok(!$@,'checkError: Kommando erfolgreich ausgeführt');

    system('false'); # Fix: CPAN Testers
    eval { Quiq::Shell->checkError($?,$!) };
    $self->like($@,qr/CMD-00002/,'checkError: Kommando endete mit Fehler');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Shell::Test->runTests;

# eof
