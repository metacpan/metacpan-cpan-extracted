#!/usr/bin/env perl

package Quiq::Gd::Component::ScatterGraph::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Gd::Image;
use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Gd::Component::ScatterGraph');
}

# -----------------------------------------------------------------------------

sub test_unitTest_no_arguments : Test(4) {
    my $self = shift;

    my $width = 200;
    my $height = 400;

    my $g = Quiq::Gd::Component::ScatterGraph->new(
        width => $width,
        height => $height,
        pointSize => 11,
        pointStyle => 'circle',
        lineThickness => 1,
        adaptPlotRegion => 1,
        x => [1,2,3,4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
        y => [1,4,9,16,25,36,49,64,81,100,121,144,169,196,225,256],
        z => [16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1], # umgekehrter
                                                       # Farbverlauf
        zLogarithmic => 0,
    );
    $self->is(ref $g,'Quiq::Gd::Component::ScatterGraph');

    $self->is($g->zMin,1);
    $self->is($g->zMax,16);

    my $img = Quiq::Gd::Image->new($width,$height);
    $img->background('ffffff');
    $img->border('f0f0f0');

    $g->render($img,0,0,
        colors => [$img->rainbowColors(16)],
        lowColor => $img->color('#003366'),
        highColor => $img->color('#ff00ff'),
    );

    my $file = '/tmp/colorgraph.png';
    Quiq::Path->write($file,$img->png);
    $self->ok(-e $file);

    # auskommentieren, um erzeugtes Bild anzusehen
    #Quiq::Path->delete($file);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Gd::Component::ScatterGraph::Test->runTests;

# eof
