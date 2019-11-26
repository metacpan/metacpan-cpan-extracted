#!/usr/bin/env perl

package Quiq::Schedule::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

use Quiq::Test::Class;
use Quiq::FileHandle;
use Quiq::Schedule;
use Quiq::Epoch;
use Quiq::Gd::Component::BlockDiagram;
use Quiq::Axis::Numeric;
use Quiq::Gd::Font;
use Quiq::Gd::Component::Axis;
use Quiq::Axis::Time;
use Quiq::Gd::Component::Grid;
use Quiq::Gd::Image;
use Quiq::Path;
use Quiq::File::Image;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Schedule');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(8) {
    my $self = shift;

    # Daten einlesen und Prozess-Objekte erzeugen

    my $dataFile = Quiq::Test::Class->testPath(
        'quiq/test/data/db/process.dat');
    my $fh = Quiq::FileHandle->new('<',$dataFile);

    my @objects;
    while (<$fh>) {
        chomp;
        my $prc = [split /\t/];

        # Einschränkung auf einen kleineren Teil
        if ($prc->[4] le '2019-10-30 08') {
            next;
        }

        push @objects,$prc;
    }
    $fh->close;

    # Prozess-Matrix erzeugen

    my $mtx = Quiq::Schedule->new(\@objects,sub {
        my $obj = shift;

        # my $begin = 

        return (
            Quiq::Epoch->new($obj->[4])->epoch,
            defined $obj->[5]? Quiq::Epoch->new($obj->[5])->epoch: undef,
        );
    });

    # Klasse, Anzahl Zeitschienen, Anzahl Einträge auf der
    # längsten Zeitschiene

    $self->is(ref $mtx,'Quiq::Schedule');
    # $self->is($mtx->width,396);
    $self->is($mtx->width,30);
    # $self->is($mtx->maxLength,162);
    $self->is($mtx->maxLength,36);

    # Einträge auf der ersten Zeitschiene
    
    my @entries = $mtx->entries(0);
    # $self->is(scalar @entries,162);
    $self->is(scalar @entries,29);

    # Einträge auf allen Zeitschienen zusammen

    @entries = $mtx->entries;
    ## $self->is(scalar @entries,3126);
    $self->is(scalar @entries,203);

    # Zeitgrenzen

    my $t = Quiq::Epoch->new($mtx->minTime)->as('YYYY-MM-DD HH:MI:SS');
    # $self->is($t,'2019-10-29 18:54:30');
    $self->is($t,'2019-10-30 08:00:10');

    $t = Quiq::Epoch->new($mtx->maxTime)->as('YYYY-MM-DD HH:MI:SS');
    $self->is($t,'2019-10-30 15:08:47');

    # Grafik erzeugen

    my $width = $mtx->width * 12;
    my $height = ($mtx->maxTime-$mtx->minTime)/30; # 1 Pixel == 30s

    my $g = Quiq::Gd::Component::BlockDiagram->new(
        width => $width,
        height => $height,
        xMin => 0,
        xMax => $mtx->width, # Wegen der Blockdarstellung +1
        yMin => $mtx->minTime,
        yMax => $mtx->maxTime,
        objects => \@entries,
        objectCallback => sub {
            my $obj = shift;

            my $color;
            my $height = $obj->end-$obj->begin;
            my $border = 1;
            if ($obj->object->[1] eq 'FAIL') {
                $color = '#ff0000';
                if ($height <= 90) {
                    $border = 0;
                }
            }
            elsif ($obj->object->[1] eq 'STRT') {
                $color = '#1c4de1';
            }
            elsif ($obj->object->[0] eq 'UOW') {
                # $color = '#ffff00';
                $color = '#ffd700';
            }
            else { # PE
                # $color = '#00ff00';
                $color = '#0dcc1e';
            }

            return (
                $obj->timeline, # x-Position
                $obj->begin,    # y-Position
                1,              # Block-Breite
                $height,        # Block-Höhe
                $color,         # Block-Farbe
                $border,
            ),
        },
    );

    my $labelOffset = 12/11/2;
    my $ax = Quiq::Axis::Numeric->new(
        orientation => 'x',
        font => Quiq::Gd::Font->new('gdSmallFont'),
        length => $width,
        min => $labelOffset,
        max => $mtx->width + $labelOffset,
    );
    my $gAx = Quiq::Gd::Component::Axis->new(
        axis => $ax,
        tickDirection => 'u',
    );
    my $gAx2 = Quiq::Gd::Component::Axis->new(
        axis => $ax,
        tickDirection => 'd',
    );
    my $axHeight = $gAx->height;

    my $ay = Quiq::Axis::Time->new(
        orientation => 'y',
        font => Quiq::Gd::Font->new('gdSmallFont'),
        length => $height,
        min => $mtx->minTime,
        max => $mtx->maxTime,
        debug => 0,
    );
    my $gAy = Quiq::Gd::Component::Axis->new(
        axis => $ay,
        reverse => 1,
    );
    my $gAy2 = Quiq::Gd::Component::Axis->new(
        axis => $ay,
        tickDirection => 'r',
        reverse => 1,
    );
    my $ayWidth = $gAy->width;

    my $grid = Quiq::Gd::Component::Grid->new(
        xAxis => $ax,
        yAxis => $ay,
    );

    my $img = Quiq::Gd::Image->new($width+2*$ayWidth,$height+2*$axHeight);
    $img->background('#ffffff');

    $gAx->render($img,$ayWidth,$axHeight);
    $gAx2->render($img,$ayWidth,$axHeight+$height-1);
    $gAy->render($img,$ayWidth,$axHeight);
    $gAy2->render($img,$ayWidth+$width-1,$axHeight);
    $grid->render($img,$ayWidth,$axHeight);
    $g->render($img,$ayWidth,$axHeight);

    my $p = Quiq::Path->new;
    my $file = $p->tempFile;
    $p->write($file,$img->png);

    my $obj = Quiq::File::Image->new("$file");
    $self->ok(scalar $obj->size);

    my $blobFile = 'Blob/doc-image/quiq-gd-component-blockdiagram.png';
    if ($p->exists('Blob/doc-image') && $p->compare("$file",$blobFile)) {
        $p->copy("$file",$blobFile);
    }

    return;
}

# -----------------------------------------------------------------------------

package main;
Quiq::Schedule::Test->runTests;

# eof
