#!/usr/bin/env perl

package Prty::Database::Api::Dbi::Connection::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use DBI ();

# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

sub initMethod : Init(1) {
    my $self = shift;

    eval {require DBI};
    if ($@) {
        $self->skipAllTests('DBI not installed');
        return;
    }
    $self->ok(1);
}

# -----------------------------------------------------------------------------

package main;
Prty::Database::Api::Dbi::Connection::Test->runTests;

# eof
