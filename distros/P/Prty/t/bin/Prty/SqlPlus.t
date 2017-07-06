#!/usr/bin/env perl

package Prty::SqlPlus::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::SqlPlus');
}

# -----------------------------------------------------------------------------

sub test_script : Test(4) {
    my $self = shift;

    my $script = Prty::SqlPlus->script('test.sql',q|
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

    # Prty::Path->write('test.sql',$script);
}

# -----------------------------------------------------------------------------

package main;
Prty::SqlPlus::Test->runTests;

# eof
