#!/usr/bin/env perl

package Quiq::Duration::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Duration');
}

# -----------------------------------------------------------------------------

sub test_new_sec : Test(3) {
    my $self = shift;

    my $dur = Quiq::Duration->new(0);
    $self->is($$dur,0);

    $dur = Quiq::Duration->new(1.375);
    $self->is($$dur,1.375);

    $dur = Quiq::Duration->new(123456789.123456789);
    $self->is($$dur,123456789.123456789);
}

sub test_new_str : Test(6) {
    my $self = shift;

    my $dur = Quiq::Duration->new('0s');
    $self->is($$dur,0);

    $dur = Quiq::Duration->new('1234s');
    $self->is($$dur,1234);

    $dur = Quiq::Duration->new('4.321s');
    $self->is($$dur,4.321);

    $dur = Quiq::Duration->new('5m4.321s');
    $self->is($$dur,304.321);

    $dur = Quiq::Duration->new('6h5m4.321s');
    $self->is($$dur,21_904.321);

    $dur = Quiq::Duration->new('7d6h5m4.321s');
    $self->is($$dur,626_704.321);
}

sub test_new_dot : Test(6) {
    my $self = shift;

    my $dur = Quiq::Duration->new('0');
    $self->is($$dur,0);

    $dur = Quiq::Duration->new('1234');
    $self->is($$dur,1234);

    $dur = Quiq::Duration->new('4.321');
    $self->is($$dur,4.321);

    $dur = Quiq::Duration->new('5:4.321');
    $self->is($$dur,304.321);

    $dur = Quiq::Duration->new('6:5:4.321');
    $self->is($$dur,21_904.321);

    $dur = Quiq::Duration->new('7:6:5:4.321');
    $self->is($$dur,626_704.321);
}

# -----------------------------------------------------------------------------

sub test_asSeconds : Test(1) {
    my $self = shift;

    my $sec = Quiq::Duration->new('152d5h25m3.457s')->asSeconds;    
    $self->is($sec,13152303.457);
}

# -----------------------------------------------------------------------------

sub test_asString : Test(1) {
    my $self = shift;

    my $str = Quiq::Duration->new(13152303.457)->asString(3);    
    $self->is($str,'152d5h25m3.457s');
}

# -----------------------------------------------------------------------------

sub test_asShortString : Test(9) {
    my $self = shift;

    my $str = Quiq::Duration->new(0)->asShortString;    
    $self->is($str,'');

    $str = Quiq::Duration->new(0)->asShortString(-notBlank=>1);    
    $self->is($str,'0s');

    $str = Quiq::Duration->new(0)->asShortString(-notBlank=>1,-minUnit=>'m');    
    $self->is($str,'0m');

    $str = Quiq::Duration->new(86400)->asShortString;    
    $self->is($str,'1d');

    # -maxUnit

    $str = Quiq::Duration->new(86400)->asShortString(-maxUnit=>'h');
    $self->is($str,'24h');

    $str = Quiq::Duration->new(131160)->asShortString(-maxUnit=>'h');
    $self->is($str,'36h26m');

    # -minUnit

    $str = Quiq::Duration->new(0)->asShortString(-minUnit=>'m');
    $self->is($str,'');

    $str = Quiq::Duration->new(65)->asShortString(-minUnit=>'m');
    $self->is($str,'1m');

    $str = Quiq::Duration->new(105)->asShortString(-minUnit=>'m');
    $self->is($str,'2m');
}

# -----------------------------------------------------------------------------

sub test_asArray : Test(4) {
    my $self = shift;

    my @arr = Quiq::Duration->new(0)->asArray;    
    $self->isDeeply(\@arr,[0,0,0,0]);

    @arr = Quiq::Duration->new(99)->asArray;    
    $self->isDeeply(\@arr,[0,0,1,39]);

    @arr = Quiq::Duration->new(13152303)->asArray;    
    $self->isDeeply(\@arr,[152,5,25,3]);

    @arr = Quiq::Duration->new(13152303.125)->asArray;    
    $self->isDeeply(\@arr,[152,5,25,3.125]);
}

# -----------------------------------------------------------------------------

sub test_asFFmpegString : Test(6) {
    my $self = shift;

    my $str = Quiq::Duration->new(0)->asFFmpegString;
    $self->is($str,'0:0:0.000');

    $str = Quiq::Duration->new(1.234)->asFFmpegString;
    $self->is($str,'0:0:1.234');

    $str = Quiq::Duration->new(1.654)->asFFmpegString;
    $self->is($str,'0:0:1.654');

    $str = Quiq::Duration->new(99.654)->asFFmpegString;
    $self->is($str,'0:1:39.654');

    $str = Quiq::Duration->new(60)->asFFmpegString;
    $self->is($str,'0:1:0.000');

    $str = Quiq::Duration->new(60.4)->asFFmpegString;
    $self->is($str,'0:1:0.400');
}

# -----------------------------------------------------------------------------

sub test_stringToSeconds : Test(8) {
    my $self = shift;

    my $sec = Quiq::Duration->stringToSeconds('3');
    $self->is($sec,3);

    $sec = Quiq::Duration->stringToSeconds('3s');
    $self->is($sec,3);

    $sec = Quiq::Duration->stringToSeconds('1234s');
    $self->is($sec,1234);

    $sec = Quiq::Duration->stringToSeconds('4.321s');
    $self->is($sec,4.321);

    $sec = Quiq::Duration->stringToSeconds('5m4.321s');
    $self->is($sec,304.321);

    $sec = Quiq::Duration->stringToSeconds('6h5m4.321s');
    $self->is($sec,21_904.321);

    $sec = Quiq::Duration->stringToSeconds('7d6h5m4.321s');
    $self->is($sec,626_704.321);

    $sec = Quiq::Duration->stringToSeconds('152d5h25m3.457s');    
    $self->is($sec,13152303.457);
}

# -----------------------------------------------------------------------------

sub test_stringToSeconds_dotNotation : Test(6) {
    my $self = shift;

    my $sec = Quiq::Duration->stringToSeconds('1234');
    $self->is($sec,1234);

    $sec = Quiq::Duration->stringToSeconds('4.321');
    $self->is($sec,4.321);

    $sec = Quiq::Duration->stringToSeconds('5:4.321');
    $self->is($sec,304.321);

    $sec = Quiq::Duration->stringToSeconds('6:5:4.321');
    $self->is($sec,21_904.321);

    $sec = Quiq::Duration->stringToSeconds('7:6:5:4.321');
    $self->is($sec,626_704.321);

    $sec = Quiq::Duration->stringToSeconds('152:5:25:3.457');    
    $self->is($sec,13152303.457);
}

# -----------------------------------------------------------------------------

sub test_secondsToString : Test(7) {
    my $self = shift;

    my $str = Quiq::Duration->secondsToString(0);
    $self->is($str,'0s');

    $str = Quiq::Duration->secondsToString(1.234);
    $self->is($str,'1s');

    $str = Quiq::Duration->secondsToString(1.234,2);
    $self->is($str,'1.23s');

    $str = Quiq::Duration->secondsToString(1.654);
    $self->is($str,'2s');

    $str = Quiq::Duration->secondsToString(99.654,3);
    $self->is($str,'1m39.654s');

    $str = Quiq::Duration->secondsToString(60);
    $self->is($str,'1m0s');

    $str = Quiq::Duration->secondsToString(60.4);
    $self->is($str,'1m0s');
}

# -----------------------------------------------------------------------------

sub test_secondsToString_fixed : Test(3) {
    my $self = shift;

    my $str = Quiq::Duration->secondsToString(0,'m');
    $self->is($str,'0s');

    $str = Quiq::Duration->secondsToString(127,'m');
    $self->is($str,'2m07s');

    $str = Quiq::Duration->secondsToString(3727,'m');
    $self->is($str,'1h02m07s');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Duration::Test->runTests;

# eof
