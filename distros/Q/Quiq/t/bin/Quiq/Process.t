#!/usr/bin/env perl

package Quiq::Process::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Process');
}

# -----------------------------------------------------------------------------

sub test_cwd : Test(3) {
    my $self = shift;

    my $path1 = Cwd::cwd();
    my $path2 = Quiq::Process->cwd;
    $self->is($path1,$path2);

    $path1 = '/tmp';
    Quiq::Process->cwd($path1);
    $path2 = Quiq::Process->cwd;
    $self->is($path1,$path2);

    $path1 = '/non/existent';
    eval{Quiq::Process->cwd($path1)};
    $self->like($@,qr/PROCESS-00001/);
}

# -----------------------------------------------------------------------------

sub test_euid : Test(2) {
    my $self = shift;

    my $euid = Quiq::Process->euid;
    $self->is($euid,$>);

    Quiq::Process->euid($>);

    eval { Quiq::Process->euid(0) };
    if ($< == 0) {
        $self->ok(!$@);
    }
    else {
        $self->like($@,qr/PROCESS-00002/);
    }
}

# -----------------------------------------------------------------------------

sub test_user : Test(1) {
    my $self = shift;

    my $user = Quiq::Process->user;
    $self->ok($user);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Process::Test->runTests;

# eof
