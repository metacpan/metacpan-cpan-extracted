#!/usr/bin/env perl

package Quiq::Database::Config::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

use Quiq::Path;
use Quiq::Unindent;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Database::Config');
}

# -----------------------------------------------------------------------------

sub test_unitTest_trigger : Test(4) {
    my $self = shift;

    my $file = Quiq::Path->tempFile(Quiq::Unindent->string(q°
        db_1 => {
            udl => 'dbi#sqlite:/tmp/test.db;schema=test',
        },
        db_2 => {
        },
    °));

    my $cfg = Quiq::Database::Config->new("$file");
    $self->is(ref($cfg),'Quiq::Database::Config');

    my $udl = $cfg->udl('db_1');
    $self->is($udl,'dbi#sqlite:/tmp/test.db;schema=test');

    eval {$cfg->udl('db_2')};
    $self->like($@,qr/No UDL/i);

    eval {$cfg->udl('unknown')};
    $self->like($@,qr/Database not defined/i);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Database::Config::Test->runTests;

# eof
