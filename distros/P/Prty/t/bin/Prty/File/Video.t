#!/usr/bin/env perl

package Prty::File::Video::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Prty::System;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::File::Video');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(10) {
    my $self = shift;

    # Fix: CPAN Testers

    if (!Prty::System->searchProgram('ffprobe',-sloppy=>1)) {
        $self->skipTest('ffprobe not found');
        return;
    }

    my $file = $self->testPath(
        't/data/video/fluch-von-novgorod.mp4');

    my $vid = Prty::File::Video->new($file);
    $self->is(ref($vid),'Prty::File::Video');

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
    $self->is($bitrate=>6455);

    my $framerate = $vid->framerate;
    $self->is($framerate=>12);

    my $duration = $vid->duration;
    $self->is($duration=>8.417);

    my $frames = $vid->frames;
    $self->is($frames=>101);
}

# -----------------------------------------------------------------------------

package main;
Prty::File::Video::Test->runTests;

# eof
