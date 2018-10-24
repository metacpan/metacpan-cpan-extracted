#!/usr/bin/env perl

package Prty::Converter::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Converter');
}

# -----------------------------------------------------------------------------

sub test_snakeCaseToCamelCase : Test(2) {
    my $self = shift;

    my $camel = Prty::Converter->snakeCaseToCamelCase('ims-apply-delta-row-by-row');
    $self->is($camel,'imsApplyDeltaRowByRow');

    $camel = Prty::Converter->snakeCaseToCamelCase('ims_apply_delta_row_by_row');
    $self->is($camel,'imsApplyDeltaRowByRow');
}

# -----------------------------------------------------------------------------

sub test_strToHex : Test(1) {
    my $self = shift;

    my $val = Prty::Converter->strToHex('Franz Strauß');
    $self->is($val,'46 72 61 6e 7a 20 53 74 72 61 75 df');
}

# -----------------------------------------------------------------------------

sub test_umlautToAscii : Test(4) {
    my $self = shift;

    my $str1 = 'äöüÄÖÜß';

    # Rückgabewert
    my $str2 = Prty::Converter->umlautToAscii($str1);
    $self->is($str1,'äöüÄÖÜß');
    $self->is($str2,'aeoeueAeOeUess');

    # in-place
    $str2 = Prty::Converter->umlautToAscii(\$str1);
    $self->is($str1,'aeoeueAeOeUess');
    $self->is($str2,undef);
}

# -----------------------------------------------------------------------------

sub test_germanToProgramNumber : Test(2) {
    my $self = shift;

    my $x = Prty::Converter->germanToProgramNumber('12,34');
    $self->is($x,'12.34');

    $x = Prty::Converter->germanToProgramNumber('12.345,67');
    $self->is($x,'12345.67');
}

# -----------------------------------------------------------------------------

sub test_ptToPx : Test(1) {
    my $self = shift;

    my $px = Prty::Converter->ptToPx(75);
    $self->is($px,100);
}

# -----------------------------------------------------------------------------

sub test_pxToPt : Test(1) {
    my $self = shift;

    my $pt = Prty::Converter->pxToPt(100);
    $self->is($pt,75);
}

# -----------------------------------------------------------------------------

sub test_epochToDuration : Test(2) {
    my $self = shift;
    
    my $val = Prty::Converter->epochToDuration(0);
    $self->is($val,'00:00:00');

    $val = Prty::Converter->epochToDuration(3601);
    $self->is($val,'01:00:01');
}

# -----------------------------------------------------------------------------

sub test_timestampToEpoch : Test(3) {
    my $self = shift;

    $ENV{'TZ'} = 'CET'; # Fix: CPAN Testers
    
    # Alle Angaben
    my $t = Prty::Converter->timestampToEpoch('2014-11-18 14:05:06,690');
    $self->is($t,'1416315906.690');

    # Ohne Sekundenbruchteile  
    $t = Prty::Converter->timestampToEpoch('2014-11-18 14:05:06');
    $self->is($t,1416315906);

    # Ohne Zeitanteil
    $t = Prty::Converter->timestampToEpoch('2014-11-18');
    $self->is($t,1416265200);
}

# -----------------------------------------------------------------------------

sub test_epochToTimestamp : Test(3) {
    my $self = shift;

    $ENV{'TZ'} = 'CET'; # Fix: CPAN Testers
     
    # Alle Angaben
    my $timestamp = Prty::Converter->epochToTimestamp('1416315906.690');
    $self->is($timestamp,'2014-11-18 14:05:06,690');

    # Ohne Sekundenbruchteile  
    $timestamp = Prty::Converter->epochToTimestamp(1416315906);
    $self->is($timestamp,'2014-11-18 14:05:06');

    # Ohne Zeitanteil
    $timestamp = Prty::Converter->epochToTimestamp(1416265200);
    $self->is($timestamp,'2014-11-18 00:00:00');
}

# -----------------------------------------------------------------------------

sub test_stringToKeyVal : Test(1) {
    my $self = shift;

    my $str = q| var1=val1 var2="val2a val2b" var3=val3 var4="val4"|;
    my @arr = Prty::Converter->stringToKeyVal($str);
    $self->isDeeply(\@arr,
        ['var1','val1','var2','val2a val2b','var3','val3','var4','val4']);
}

# -----------------------------------------------------------------------------

package main;
Prty::Converter::Test->runTests;

# eof
