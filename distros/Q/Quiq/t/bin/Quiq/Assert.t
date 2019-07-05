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

sub test_isEnumValue : Test(4) {
    my $self = shift;

    eval {Quiq::Assert->isEnumValue(undef,[qw/a b c/])};
    $self->is($@,'');

    eval {Quiq::Assert->isEnumValue('',[qw/a b c/])};
    $self->is($@,'');

    eval {Quiq::Assert->isEnumValue('b',[qw/a b c/])};
    $self->is($@,'');

    eval {Quiq::Assert->isEnumValue('x',[qw/a b c/])};
    $self->like($@,qr/Value not allowed/i);
}

# -----------------------------------------------------------------------------

sub test_isNotNull : Test(3) {
    my $self = shift;

    eval {Quiq::Assert->isNotNull(undef)};
    $self->like($@,qr/is null/i);

    eval {Quiq::Assert->isNotNull('')};
    $self->like($@,qr/is null/i);

    eval {Quiq::Assert->isNotNull('x')};
    $self->is($@,'');
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

package main;
Quiq::Assert::Test->runTests;

# eof
