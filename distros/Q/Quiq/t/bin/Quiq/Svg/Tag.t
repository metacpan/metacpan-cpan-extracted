#!/usr/bin/env perl

package Quiq::Svg::Tag::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

use Quiq::Path;
use Quiq::Shell;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Svg::Tag');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(5) {
    my $self = shift;

    # Instantiierung

    my $t = Quiq::Svg::Tag->new;
    $self->is(ref $t,'Quiq::Svg::Tag');

    # Präambel

    my $svg = $t->preamble;
    $self->like($svg,qr/<!DOCTYPE/);

    $svg = $t->tag('svg',width=>400,height=>300);
    $self->like($svg,qr/width="400"/);
    $self->like($svg,qr/height="300"/);
    $self->like($svg,qr{\Qxmlns:xlink="http://www.w3.org/1999/xlink"});

    $svg = $t->cat(
        $t->preamble,
        $t->tag('svg',
            width => 80,
            height => 80,
            $t->tag('circle',
                cx => 40,
                cy => 40,
                r => 39,
                style => 'stroke: black; fill: yellow',
            ),
        ),
    );

    # SVG-Datei ins Blob-Verzeichnis schreiben

    my $p = Quiq::Path->new;
    my $sh = Quiq::Shell->new(log=>1,logDest=>*STDERR);

    my $svgFile = 'Blob/doc-image/quiq-svg-tag-01.svg';
    if ($p->exists('Blob/doc-image') && $p->compareData("$svgFile",$svg)) {
        $p->write("$svgFile",$svg);
        my $pngFile = $p->newExtension($svgFile,'png');
        $sh->exec("convert -transparent white $svgFile $pngFile");
    }
}

# -----------------------------------------------------------------------------

package main;
Quiq::Svg::Tag::Test->runTests;

# eof
