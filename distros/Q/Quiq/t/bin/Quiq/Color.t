#!/usr/bin/env perl

package Quiq::Color::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Color');
}

# -----------------------------------------------------------------------------

sub test_new : Test(4) {
    my $self = shift;

    # $r,$g,$b

    my $col = Quiq::Color->new(255,255,0);
    $self->isDeeply($col,[[255,255,0],undef]);

    # \@rgb

    $col = Quiq::Color->new([255,0,0]);
    $self->isDeeply($col,[[255,0,0],undef]);

    # 'rrggbb'

    $col = Quiq::Color->new('00ff00');
    $self->isDeeply($col,[[0,255,0],undef]);

    # '#rrggbb'

    $col = Quiq::Color->new('#00ff00');
    $self->isDeeply($col,[[0,255,0],undef]);
}

# -----------------------------------------------------------------------------

sub test_brightness : Test(3) {
    my $self = shift;

    # schwarz

    my $brightness = Quiq::Color->new('000000')->brightness;
    $self->is($brightness,0);

    # weiß

    $brightness = Quiq::Color->new('ffffff')->brightness;
    $self->is($brightness,255);

    # rot

    $brightness = Quiq::Color->new('ff0000')->brightness;
    $self->floatIs($brightness,139.44);
}

# -----------------------------------------------------------------------------

sub test_name : Test(3) {
    my $self = shift;

    my $col = Quiq::Color->new(255,0,0);
    my $name = $col->name;
    $self->is($name,'');

    $name = $col->name('red');
    $self->is($name,'red');

    $name = $col->name;
    $self->is($name,'red');
}

# -----------------------------------------------------------------------------

sub test_hexString : Test(1) {
    my $self = shift;

    my $str = Quiq::Color->new(255,255,255)->hexString;
    $self->is($str,'ffffff');
}

# -----------------------------------------------------------------------------

sub test_rgb : Test(2) {
    my $self = shift;

    # @rgb

    my @rgb = Quiq::Color->new(255,250,250)->rgb;
    $self->isDeeply(\@rgb,[255,250,250]);

    # $rgbA

    my $rgbA = Quiq::Color->new(255,250,250)->rgb;
    $self->isDeeply($rgbA,[255,250,250]);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Color::Test->runTests;

# eof
