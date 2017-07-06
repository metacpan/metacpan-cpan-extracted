#!/usr/bin/env perl

package Prty::Process::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Process');
}

# -----------------------------------------------------------------------------

sub test_cwd : Test(3) {
    my $self = shift;

    my $path1 = Cwd::cwd();
    my $path2 = Prty::Process->cwd;
    $self->is($path1,$path2);

    $path1 = '/tmp';
    Prty::Process->cwd($path1);
    $path2 = Prty::Process->cwd;
    $self->is($path1,$path2);

    $path1 = '/non/existent';
    eval{Prty::Process->cwd($path1)};
    $self->like($@,qr/PROC-00001/);
}

# -----------------------------------------------------------------------------

sub test_euid : Test(2) {
    my $self = shift;

    my $euid = Prty::Process->euid;
    $self->is($euid,$>);

    Prty::Process->euid($>);

    eval { Prty::Process->euid(0) };
    if ($< == 0) {
        $self->ok(!$@);
    }
    else {
        $self->like($@,qr/PROC-00002/);
    }
}

# -----------------------------------------------------------------------------

sub test_user : Test(1) {
    my $self = shift;

    my $user = Prty::Process->user;
    $self->ok($user);
}

# -----------------------------------------------------------------------------

package main;
Prty::Process::Test->runTests;

# eof
