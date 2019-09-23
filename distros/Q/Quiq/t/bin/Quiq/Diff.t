#!/usr/bin/env perl

package Quiq::Diff::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Diff');
}

# -----------------------------------------------------------------------------

sub test_diff : Test(1) {
    my $self = shift;

    my $expected = Quiq::Unindent->string(q~
        2c2
        < B
        ---
        > D
    ~);

    my $diff = Quiq::Diff->diff("A\nB\nC\n","A\nD\nC\n");
    $self->is($diff,$expected);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Diff::Test->runTests;

# eof
