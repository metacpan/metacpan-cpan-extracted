#!/usr/bin/env perl

package Prty::Database::Api::Dbi::Connection::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

sub initMethod : Init(1) {
    my $self = shift;

    eval { require DBI };
    if ($@) {
        $self->skipAllTests('DBI nicht installiert');
        return;
    }
    $self->ok(1);
}

# -----------------------------------------------------------------------------

package main;
Prty::Database::Api::Dbi::Connection::Test->runTests;

# eof
