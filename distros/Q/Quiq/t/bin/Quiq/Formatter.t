#!/usr/bin/env perl

package Quiq::Formatter::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Formatter');
}

# -----------------------------------------------------------------------------

sub test_normalizeNumber : Test(6) {
    my $self = shift;

    # 123.456000 -> 123.456
    # 70.00 -> 70
    # 0.0 -> 0
    # -0.0 -> 0
    # 007 -> 7
    # 23,7 -> 23.7

    my $x = Quiq::Formatter->normalizeNumber('123.456000');
    $self->is($x,'123.456','normalizeNumber: 123.456000 -> 123.456');

    $x = Quiq::Formatter->normalizeNumber('70.00');
    $self->is($x,'70','normalizeNumber: 70.00 -> 70');

    $x = Quiq::Formatter->normalizeNumber('0.0');
    $self->is($x,'0','normalizeNumber: 0.0 -> 0');

    $x = Quiq::Formatter->normalizeNumber('-0.0');
    $self->is($x,'0','normalizeNumber: -0.0 -> 0');

    $x = Quiq::Formatter->normalizeNumber('007');
    $self->is($x,'7','normalizeNumber: 007 -> 7');

    $x = Quiq::Formatter->normalizeNumber('23,7');
    $self->is($x,'23.7','normalizeNumber: 23,7 -> 23.7');
}

# -----------------------------------------------------------------------------

sub test_readableNumber : Test(10) {
    my $self = shift;

    my @arg =  ( 1,  12,  12345,   -12345678,    1234.5678);
    my @val1 = ('1','12','12.345','-12.345.678','1.234,5678');
    my @val2 = ('1','12','12,345','-12,345,678','1,234.5678');

    for (my $i = 0; $i < @arg; $i++) {
        my $val = Quiq::Formatter->readableNumber($arg[$i]);
        $self->is($val,$val1[$i],"readableNumber: $arg[$i]");

        $val = Quiq::Formatter->readableNumber($arg[$i],',');
        $self->is($val,$val2[$i],"readableNumber: $arg[$i]");
    }
}

# -----------------------------------------------------------------------------

package main;
Quiq::Formatter::Test->runTests;

# eof
