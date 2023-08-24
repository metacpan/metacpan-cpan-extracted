#!/usr/bin/env perl

package Quiq::Converter::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Converter');
}

# -----------------------------------------------------------------------------

sub test_camelCaseToSnakeCase : Test(1) {
    my $self = shift;

    my $camel = Quiq::Converter->camelCaseToSnakeCase('imsApplyDeltaRowByRow');
    $self->is($camel,'ims-apply-delta-row-by-row');
}

# -----------------------------------------------------------------------------

sub test_snakeCaseToCamelCase : Test(2) {
    my $self = shift;

    my $camel = Quiq::Converter->snakeCaseToCamelCase('ims-apply-delta-row-by-row');
    $self->is($camel,'imsApplyDeltaRowByRow');

    $camel = Quiq::Converter->snakeCaseToCamelCase('ims_apply_delta_row_by_row');
    $self->is($camel,'imsApplyDeltaRowByRow');
}

# -----------------------------------------------------------------------------

sub test_protectRegexChars : Test(1) {
    my $self = shift;

    my $val = Quiq::Converter->protectRegexChars('a\b.x{~Z');
    $self->is($val,'a\\\\b\.x\{~Z');
}

# -----------------------------------------------------------------------------

sub test_strToHex : Test(1) {
    my $self = shift;

    my $val = Quiq::Converter->strToHex('Franz Strauß');
    $self->is($val,'46 72 61 6e 7a 20 53 74 72 61 75 df');
}

# -----------------------------------------------------------------------------

sub test_umlautToAscii : Test(4) {
    my $self = shift;

    my $str1 = 'äöüÄÖÜß';

    # Rückgabewert
    my $str2 = Quiq::Converter->umlautToAscii($str1);
    $self->is($str1,'äöüÄÖÜß');
    $self->is($str2,'aeoeueAeOeUess');

    # in-place
    $str2 = Quiq::Converter->umlautToAscii(\$str1);
    $self->is($str1,'aeoeueAeOeUess');
    $self->is($str2,undef);
}

# -----------------------------------------------------------------------------

sub test_germanNumber : Test(2) {
    my $self = shift;

    my $x = Quiq::Converter->germanNumber('12,34');
    $self->is($x,'12.34');

    $x = Quiq::Converter->germanNumber('12.345,67');
    $self->is($x,'12345.67');
}

# -----------------------------------------------------------------------------

sub test_germanMoneyAmount : Test(2) {
    my $self = shift;

    my $x = Quiq::Converter->germanMoneyAmount('12,343');
    $self->is($x,'12.34');

    $x = Quiq::Converter->germanMoneyAmount('12.345,6755');
    $self->is($x,'12345.68');
}

# -----------------------------------------------------------------------------

sub test_ptToPx : Test(1) {
    my $self = shift;

    my $px = Quiq::Converter->ptToPx(75);
    $self->is($px,100);
}

# -----------------------------------------------------------------------------

sub test_pxToPt : Test(1) {
    my $self = shift;

    my $pt = Quiq::Converter->pxToPt(100);
    $self->is($pt,75);
}

# -----------------------------------------------------------------------------

sub test_epochToDuration : Test(2) {
    my $self = shift;
    
    my $val = Quiq::Converter->epochToDuration(0);
    $self->is($val,'00:00:00');

    $val = Quiq::Converter->epochToDuration(3601);
    $self->is($val,'01:00:01');
}

# -----------------------------------------------------------------------------

sub test_timestampToEpoch : Test(3) {
    my $self = shift;

    $ENV{'TZ'} = 'CET'; # Fix: CPAN Testers
    
    # Alle Angaben
    my $t = Quiq::Converter->timestampToEpoch('2014-11-18 14:05:06,690');
    $self->is($t,'1416315906.690');

    # Ohne Sekundenbruchteile  
    $t = Quiq::Converter->timestampToEpoch('2014-11-18 14:05:06');
    $self->is($t,1416315906);

    # Ohne Zeitanteil
    $t = Quiq::Converter->timestampToEpoch('2014-11-18');
    $self->is($t,1416265200);
}

# -----------------------------------------------------------------------------

sub test_epochToTimestamp : Test(3) {
    my $self = shift;

    $ENV{'TZ'} = 'CET'; # Fix: CPAN Testers
     
    # Alle Angaben
    my $timestamp = Quiq::Converter->epochToTimestamp('1416315906.690');
    $self->is($timestamp,'2014-11-18 14:05:06,690');

    # Ohne Sekundenbruchteile  
    $timestamp = Quiq::Converter->epochToTimestamp(1416315906);
    $self->is($timestamp,'2014-11-18 14:05:06');

    # Ohne Zeitanteil
    $timestamp = Quiq::Converter->epochToTimestamp(1416265200);
    $self->is($timestamp,'2014-11-18 00:00:00');
}

# -----------------------------------------------------------------------------

sub test_stringToKeyVal : Test(1) {
    my $self = shift;

    my $str = q| var1=val1 var2="val2a val2b" var3=val3 var4="val4"|;
    my @arr = Quiq::Converter->stringToKeyVal($str);
    $self->isDeeply(\@arr,
        ['var1','val1','var2','val2a val2b','var3','val3','var4','val4']);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Converter::Test->runTests;

# eof
