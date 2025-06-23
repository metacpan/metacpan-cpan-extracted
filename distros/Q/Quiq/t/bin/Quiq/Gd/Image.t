#!/usr/bin/env perl

package Quiq::Gd::Image::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub initMethod : Init(2) {
    my $self = shift;

    eval {require GD};
    if ($@) {
        $self->skipAllTests('GD not installed');
        return;
    }
    $self->ok(1);

    $self->useOk('Quiq::Gd::Image');
}

sub test_unitTest : Test(4) {
    my $self = shift;

    my $img = Quiq::Gd::Image->new(100,100);
    $self->is(ref($img),'Quiq::Gd::Image','new');

    my $white = $img->background(255,255,255);
    $self->ok($white >= 0,'background');

    my $white2 = $img->color(255,255,255);
    $self->is($white,$white2);

    my $black = $img->color(0,0,0);
    $self->isnt($black,$white);
}

# -----------------------------------------------------------------------------

sub test_color_truecolor : Test(9) {
    my $self = shift;

    my $img = Quiq::Gd::Image->new(100,100); # TrueColor
    my $black = $img->color('#000000');
    my $white = $img->color('#ffffff');
    $self->isnt($white,$black);
    my $white2 = $img->color('#ffffff');
    $self->is($white2,$white);

    # Dasselbe mit Farbangabe ohne #

    $black = $img->color('000000');
    $white = $img->color('ffffff');
    $self->isnt($white,$black);
    $white2 = $img->color('ffffff');
    $self->is($white2,$white);

    # ($r,$g,$b) und [$r,$g,$b]
    my $color1 = $img->color(50,100,200);
    my $color2 = $img->color([50,100,200]);
    $self->is($color2,$color2);

    # Defaultfarbe
    my $color = $img->color(undef);
    $self->is($color,$black);

    # Defaultfarbe
    $color = $img->color;
    $self->is($color,$black);

    # GD-Farbe
    $color = $img->color($black);
    $self->is($color,$black);

    $color = $img->color($white);
    $self->is($color,$white);
}

sub test_color_palette : Test(7) {
    my $self = shift;

    my $img = Quiq::Gd::Image->new(100,100,10); # TrueColor
    my $black = $img->color('#000000');
    my $white = $img->color('#ffffff');
    $self->isnt($white,$black);
    my $white2 = $img->color('#ffffff');
    $self->is($white2,$white);

    # ($r,$g,$b) und [$r,$g,$b]
    my $color1 = $img->color(50,100,200);
    my $color2 = $img->color([50,100,200]);
    $self->is($color2,$color2);

    # Defaultfarbe
    my $color = $img->color(undef);
    $self->is($color,$black);

    # Defaultfarbe
    $color = $img->color;
    $self->is($color,$black);

    # GD-Farbe
    $color = $img->color($black);
    $self->is($color,$black);

    $color = $img->color($white);
    $self->is($color,$white);
}

# -----------------------------------------------------------------------------

sub test_rainbowColors : Test(9) {
    my $self = shift;

    for my $n (4,8,16,32,64,128,256,512,1024) {
        my $img = Quiq::Gd::Image->new(500,20);
        my @colors = $img->rainbowColors($n);
        $self->is(scalar(@colors),$n,"rainbowColors: $n colors");
    }
}

# -----------------------------------------------------------------------------

package main;
Quiq::Gd::Image::Test->runTests;

# eof
