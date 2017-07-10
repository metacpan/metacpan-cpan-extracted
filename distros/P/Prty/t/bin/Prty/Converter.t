#!/usr/bin/env perl

package Prty::Converter::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Converter');
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
