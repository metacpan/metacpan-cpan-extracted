#!/usr/bin/env perl

package Prty::Assert::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Assert');
}

# -----------------------------------------------------------------------------

sub test_isNumber : Test(5) {
    my $self = shift;

    eval {Prty::Assert->isNumber(undef)};
    $self->is($@,'');

    eval {Prty::Assert->isNumber('')};
    $self->is($@,'');

    eval {Prty::Assert->isNumber(1)};
    $self->is($@,'');

    eval {Prty::Assert->isNumber(1.3)};
    $self->is($@,'');

    eval {Prty::Assert->isNumber('x')};
    $self->like($@,qr/Not a number/i);
}

# -----------------------------------------------------------------------------

sub test_notNull : Test(3) {
    my $self = shift;

    eval {Prty::Assert->notNull(undef)};
    $self->like($@,qr/is null/i);

    eval {Prty::Assert->notNull('')};
    $self->like($@,qr/is null/i);

    eval {Prty::Assert->notNull('x')};
    $self->is($@,'');
}

# -----------------------------------------------------------------------------

package main;
Prty::Assert::Test->runTests;

# eof
