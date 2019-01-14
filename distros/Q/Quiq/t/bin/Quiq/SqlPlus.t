#!/usr/bin/env perl

package Quiq::SqlPlus::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::SqlPlus');
}

# -----------------------------------------------------------------------------

sub test_script : Test(4) {
    my $self = shift;

    my $script = Quiq::SqlPlus->script('test.sql',q|
            SELECT
                *
            FROM
                all_users
            ORDER BY
                username
            ;
        |,
        -beforeAndAfter => q|
            SELECT
                SYSDATE
            FROM
                dual
            ;
        |,
        -author => 'Frank Seitz',
        -description => q|
            Dies ist ein Test-Skript.
        |,
    );
    $self->like($script,qr/all_users/);
    $self->like($script,qr/SYSDATE/);
    $self->like($script,qr/Frank Seitz/);
    $self->like($script,qr/Test-Skript/);

    # Quiq::Path->write('test.sql',$script);
}

# -----------------------------------------------------------------------------

package main;
Quiq::SqlPlus::Test->runTests;

# eof
