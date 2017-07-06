#!/usr/bin/env perl

package Prty::Ipc::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Ipc');
}

# -----------------------------------------------------------------------------

sub test_filter : Test(3) {
    my $self = shift;

    my ($out,$err) = Prty::Ipc->filter('/bin/cat','Ein Test');
    $self->is($out,'Ein Test');

    eval { Prty::Ipc->filter('/bin/false','Ein Test') };
    # warn "$@";
    $self->like($@,qr/ExitCode:\s+1\s+/,'Kommando schlägt fehl');

    # Dieser Test schlägt unter Perl 5.8.8 fehl, da $? (Exitcode) 0 ist
    eval { Prty::Ipc->filter('/bin/unknown_command','Ein Test') };
    # warn "$@";
    $self->like($@,qr/open3:/,'Kommando existiert nicht');
}

# -----------------------------------------------------------------------------

package main;
Prty::Ipc::Test->runTests;

# eof
