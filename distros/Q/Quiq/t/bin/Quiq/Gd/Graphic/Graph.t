#!/usr/bin/env perl

package Quiq::Gd::Graphic::Graph::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

use Quiq::Gd::Image;
use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Gd::Graphic::Graph');
}

# -----------------------------------------------------------------------------

sub test_unitTest_no_arguments : Test(5) {
    my $self = shift;

    my $g = Quiq::Gd::Graphic::Graph->new(
        width => 100,
        height => 100,
    );
    $self->is(ref $g,'Quiq::Gd::Graphic::Graph');

    my $val = $g->xMin;
    $self->is($val,-1);

    $val = $g->xMax;
    $self->is($val,1);

    $val = $g->yMin;
    $self->is($val,-1);

    $val = $g->yMax;
    $self->is($val,1);
}

sub test_unitTest_simple : Test(5) {
    my $self = shift;

    my $width = 100;
    my $height = 100;

    # Grafikobjekt instantiieren

    my $g = Quiq::Gd::Graphic::Graph->new(
        width => $width,
        height => $height,
        x => [-1,0,1],
        y => [-1,0,1],
        pointColor => 'ff0000',
        pointSize => 5,
        adaptPlotRegion => 1,
    );

    # Durch adaptPlotRegion müssen sich die Intervallgrenzen geändert haben

    $self->cmpOk($g->xMin,'<',-1);
    $self->cmpOk($g->xMax,'>',1);
    $self->cmpOk($g->yMin,'<',-1);
    $self->cmpOk($g->yMax,'>',1);

    # Grafik rendern

    my $img = Quiq::Gd::Image->new($width,$height);
    $img->background('ffffff');
    $g->render($img);

    my $file = '/tmp/polyline.png';
    Quiq::Path->write($file,$img->png);
    $self->ok(-e $file);

    # auskommentieren, um erzeugtes Bild anzusehen
    Quiq::Path->delete($file);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Gd::Graphic::Graph::Test->runTests;

# eof
