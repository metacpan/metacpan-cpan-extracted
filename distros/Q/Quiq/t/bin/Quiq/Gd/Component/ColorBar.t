#!/usr/bin/env perl

package Quiq::Gd::Component::ColorBar::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Gd::Image;
use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Gd::Component::ColorBar');
}

# -----------------------------------------------------------------------------

sub test_unitTest_no_arguments : Test(1) {
    my $self = shift;

    my $width = 300;
    my $height = 50;

    my $g = Quiq::Gd::Component::ColorBar->new(
        width => $width,
        height => $height,
    );
    $self->is(ref $g,'Quiq::Gd::Component::ColorBar');

    my $img = Quiq::Gd::Image->new($width,$height);
    $img->background('ffffff');
    $img->border('f0f0f0');

    $g->render($img,0,0);
}

sub test_unitTest_colors : Test(2) {
    my $self = shift;

    my $width = 300;
    my $height = 50;

    my $g = Quiq::Gd::Component::ColorBar->new(
        width => $width,
        height => $height,
    );
    $self->is(ref $g,'Quiq::Gd::Component::ColorBar');

    my $img = Quiq::Gd::Image->new($width,$height);
    $img->background('ffffff');
    $img->border('f0f0f0');

    $g->render($img,0,0,
        colors => [$img->rainbowColors(512)],
    );

    my $file = '/tmp/colorbar.png';
    Quiq::Path->write($file,$img->png);
    $self->ok(-e $file);

    # auskommentieren, um erzeugtes Bild anzusehen
    #Quiq::Path->delete($file);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Gd::Component::ColorBar::Test->runTests;

# eof
