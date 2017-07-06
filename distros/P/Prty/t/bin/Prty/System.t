#!/usr/bin/env perl

package Prty::System::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::System');
}

# -----------------------------------------------------------------------------

sub test_numberOfCpus : Test(1) {
    my $self = shift;

    my $n = Prty::System->numberOfCpus;
    $self->ok($n);
}

# -----------------------------------------------------------------------------

sub test_hostname : Test(2) {
    my $self = shift;

    my $hostname = Prty::System->hostname;
    $self->ok($hostname);

    my $ip = Prty::System->ip;
    $hostname = Prty::System->hostname($ip);
    $self->ok($hostname);
}

# -----------------------------------------------------------------------------

sub test_ip : Test(1) {
    my $self = shift;

    my $ip = Prty::System->ip;
    $self->ok($ip);
}

# -----------------------------------------------------------------------------

sub test_encoding : Test(1) {
    my $self = shift;

    # Folgende Setzung beeinflusst die Methode nicht
    # $ENV{'LANG'} = 'de_DE.iso-8859-1';
    my $val = Prty::System->encoding;
    $self->ok($val);
}

# -----------------------------------------------------------------------------

sub test_user : Test(2) {
    my $self = shift;

    my $user = Prty::System->user(0);
    $self->is($user,'root');

    $user = eval {Prty::System->user(123456789)};
    $self->like($@,qr/SYS-00001/);
}

# -----------------------------------------------------------------------------

sub test_uid : Test(2) {
    my $self = shift;

    my $uid = Prty::System->uid('root');
    $self->is($uid,0);

    eval {Prty::System->uid('non-existent-user')};
    $self->like($@,qr/SYS-00001/);
}

# -----------------------------------------------------------------------------

sub test_searchProgram : Test(1) {
    my $self = shift;

    my $path = Prty::System->searchProgram('ls');
    $self->isTest($path,'/bin/ls','ls gefunden');
}

# -----------------------------------------------------------------------------

package main;
Prty::System::Test->runTests;

# eof
