#!/usr/bin/env perl

package Quiq::Database::Api::Dbi::Connection::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use DBI ();

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
Quiq::Database::Api::Dbi::Connection::Test->runTests;

# eof
