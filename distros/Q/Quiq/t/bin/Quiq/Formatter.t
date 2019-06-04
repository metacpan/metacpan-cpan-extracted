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

sub test_reducedIsoTime : Test(6) {
    my $self = shift;

    # Unix Epoch (Stunden, Tag wg. localtime nicht einfach portabel zu testen)

    my $val = Quiq::Formatter->reducedIsoTime(1558593179,1530940097);
    $self->like($val,qr/2018-07-0\d \d\d:08:17/);

    $val = Quiq::Formatter->reducedIsoTime(1558593179,1558070991);
    $self->like($val,qr/1\d \d\d:29:51/);

    $val = Quiq::Formatter->reducedIsoTime(1558593179,1558593168);
    $self->is($val,'48');

    # ISO-Datum

    $val = Quiq::Formatter->reducedIsoTime('2019-05-27 15:04:03','2018-07-07 07:08:17');
    $self->is($val,'2018-07-07 07:08:17');

    $val = Quiq::Formatter->reducedIsoTime('2019-05-27 15:04:03','2019-05-17 07:29:51');
    $self->is($val,'17 07:29:51');

    $val = Quiq::Formatter->reducedIsoTime('2019-05-27 15:04:03','2019-05-27 15:04:42');
    $self->is($val,'42');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Formatter::Test->runTests;

# eof
