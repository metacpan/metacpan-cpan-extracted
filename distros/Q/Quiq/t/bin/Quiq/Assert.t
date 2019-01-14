#!/usr/bin/env perl

package Quiq::Assert::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Assert');
}

# -----------------------------------------------------------------------------

sub test_isNumber : Test(5) {
    my $self = shift;

    eval {Quiq::Assert->isNumber(undef)};
    $self->is($@,'');

    eval {Quiq::Assert->isNumber('')};
    $self->is($@,'');

    eval {Quiq::Assert->isNumber(1)};
    $self->is($@,'');

    eval {Quiq::Assert->isNumber(1.3)};
    $self->is($@,'');

    eval {Quiq::Assert->isNumber('x')};
    $self->like($@,qr/Not a number/i);
}

# -----------------------------------------------------------------------------

sub test_notNull : Test(3) {
    my $self = shift;

    eval {Quiq::Assert->notNull(undef)};
    $self->like($@,qr/is null/i);

    eval {Quiq::Assert->notNull('')};
    $self->like($@,qr/is null/i);

    eval {Quiq::Assert->notNull('x')};
    $self->is($@,'');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Assert::Test->runTests;

# eof
