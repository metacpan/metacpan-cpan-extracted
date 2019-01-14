#!/usr/bin/env perl

package Quiq::Config::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Config');
}

# -----------------------------------------------------------------------------

sub test_unitTest_file : Test(5) {
    my $self = shift;

    my $file = $self->testPath('t/data/etc/test1.conf');
    my $cfg = Quiq::Config->new($file);
    $self->is(ref($cfg),'Quiq::Config');

    my $val = $cfg->get('host');
    $self->is($val,'localhost');

    my @vals = $cfg->get(qw/host datenbank/);
    $self->isDeeply(\@vals,['localhost','entw1']);

    my $arr = $cfg->get('benutzer');
    $self->isDeeply($arr,['sys','system']);

    eval { $cfg->get('nichtExistent') };
    $self->like($@,qr/CFG-00001:/);
}

sub test_unitTest_code : Test(1) {
    my $self = shift;

    my $cfg = Quiq::Config->new('a=>1, b=>2');
    $self->is(ref($cfg),'Quiq::Config');
}

# -----------------------------------------------------------------------------

# FIXME: Tests auf Paketebene heben

sub test_get : Test(3) {
    my $self = shift;

    my $conf = Quiq::Config->new($self->testPath(
        't/data/etc/test2.conf'));

    my $val = $conf->get('SpoolDir');
    $self->is($val,'/var/opt/myapp/spool');

    my $cwd = Quiq::Process->cwd;
    $val = $conf->get('FtpUrl');
    $self->is($val,"USER:PASSW\@localhost$cwd");

    $val = $conf->try('X');
    $self->is($val,undef);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Config::Test->runTests;

# eof
