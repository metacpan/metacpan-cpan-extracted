#!/usr/bin/env perl

package Quiq::File::Video::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::System;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::File::Video');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(10) {
    my $self = shift;

    # Fix: CPAN Testers

    if (!Quiq::System->searchProgram('ffprobe',-sloppy=>1)) {
        $self->skipTest('ffprobe not found');
        return;
    }

    my $file = $self->testPath(
        't/data/video/fluch-von-novgorod.mp4');

    my $vid = Quiq::File::Video->new($file);
    $self->is(ref($vid),'Quiq::File::Video');

    my $width = $vid->width;
    $self->is($width=>640);

    my $height = $vid->height;
    $self->is($height=>360);

    ($width,$height) = $vid->size;
    $self->is($width=>640);
    $self->is($height=>360);

    my $aspectRatio = $vid->aspectRatio;
    $self->is($aspectRatio=>'16:9');

    my $bitrate = $vid->bitrate;
    $self->is($bitrate=>669);

    my $framerate = $vid->framerate;
    $self->is($framerate=>12);

    my $duration = $vid->duration;
    $self->is($duration=>1);

    my $frames = $vid->frames;
    $self->is($frames=>12);
}

# -----------------------------------------------------------------------------

package main;
Quiq::File::Video::Test->runTests;

# eof
