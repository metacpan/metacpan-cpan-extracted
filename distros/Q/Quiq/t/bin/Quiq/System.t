#!/usr/bin/env perl

package Quiq::System::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::System');
}

# -----------------------------------------------------------------------------

sub test_numberOfCpus : Test(1) {
    my $self = shift;

    my $n = Quiq::System->numberOfCpus;
    $self->ok($n);
}

# -----------------------------------------------------------------------------

sub test_hostname : Test(1) {
    my $self = shift;

    my $hostname = Quiq::System->hostname;
    $self->ok($hostname);

    # SREZIC: On most systems IP addresses are associated with reverse
    # DNS entries, but this is not everywhere the case.
    #
    # my $ip = Quiq::System->ip;
    # $hostname = Quiq::System->hostname($ip);
    # $self->ok($hostname);
}

# -----------------------------------------------------------------------------

# Der Test funktioniert unter NetBSD nicht

sub test_ip : Ignore(1) {
    my $self = shift;

    my $ip = Quiq::System->ip;
    $self->ok($ip);
}

# -----------------------------------------------------------------------------

sub test_encoding : Test(1) {
    my $self = shift;

    # Folgende Setzung beeinflusst die Methode nicht
    # $ENV{'LANG'} = 'de_DE.iso-8859-1';
    my $val = Quiq::System->encoding;
    $self->ok($val);
}

# -----------------------------------------------------------------------------

sub test_user : Test(2) {
    my $self = shift;

    my $user = Quiq::System->user(0);
    $self->is($user,'root');

    $user = eval {Quiq::System->user(123456789)};
    $self->like($@,qr/SYS-00001/);
}

# -----------------------------------------------------------------------------

sub test_uid : Test(2) {
    my $self = shift;

    my $uid = Quiq::System->uid('root');
    $self->is($uid,0);

    eval {Quiq::System->uid('non-existent-user')};
    $self->like($@,qr/SYS-00001/);
}

# -----------------------------------------------------------------------------

sub test_searchProgram : Test(1) {
    my $self = shift;

    my $path = Quiq::System->searchProgram('ls');
    $self->like($path,qr|/ls$|,'ls gefunden');
}

# -----------------------------------------------------------------------------

package main;
Quiq::System::Test->runTests;

# eof
