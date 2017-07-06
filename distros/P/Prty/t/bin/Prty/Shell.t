#!/usr/bin/env perl

package Prty::Shell::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Shell');
}

# -----------------------------------------------------------------------------

sub test_new : Test(1) {
    my $self = shift;

    my $sh = Prty::Shell->new;
    $self->is(ref($sh),'Prty::Shell');
}

# -----------------------------------------------------------------------------

sub test_exec : Test(2) {
    my $self = shift;

    eval {Prty::Shell->exec('/bin/ls >/dev/null 2>&1')};
    $self->ok(!$@,'exec: Kommando erfolgreich');

    eval {Prty::Shell->exec("/bin/not_a_command$$ >/dev/null 2>&1")};
    $self->like($@,qr/CMD-00002/,'exec: Kommando fehlgeschlagen');
}

# -----------------------------------------------------------------------------

sub test_checkError : Test(2) {
    my $self = shift;

    # system('/no/cmd 4711'); # FIXME: Ausgabe auf STDERR unterdrücken
    # eval { Prty::Shell->checkError($?,$!) };
    # $self->like($@,qr/CMD-00001/,
    #     'checkError: Kommando konnte nicht gestartet werden';

    system('/bin/true');
    eval { Prty::Shell->checkError($?,$!) };
    $self->ok(!$@,'checkError: Kommando erfolgreich ausgeführt');

    system('/bin/false');
    eval { Prty::Shell->checkError($?,$!) };
    $self->like($@,qr/CMD-00002/,'checkError: Kommando endete mit Fehler');
}

# -----------------------------------------------------------------------------

package main;
Prty::Shell::Test->runTests;

# eof
