#!/usr/bin/env perl

package Quiq::FFmpeg::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

use Quiq::ExampleCode;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::FFmpeg');
}

# -----------------------------------------------------------------------------

sub test_new : Test(1) {
    my $self = shift;

    my $cmd = Quiq::FFmpeg->new;
    $self->is(ref($cmd),'Quiq::FFmpeg');
}

# -----------------------------------------------------------------------------

sub test_addOption : Test(2) {
    my $self = shift;

    my $cmd = Quiq::FFmpeg->new;
    $cmd->addOption('-y');
    $self->is($cmd->command,'-y');
    
    $cmd->addOption(-i=>'GOPR1409.mp4');
    $self->is($cmd->command,q|-y -i 'GOPR1409.mp4'|);
}
    

# -----------------------------------------------------------------------------

sub test_addInput : Test(2) {
    my $self = shift;

    my $cmd = Quiq::FFmpeg->new;
    $cmd->addInput('video/GOPR1409.mp4');
    $self->is($cmd->command,q|-i 'video/GOPR1409.mp4'|);

    $cmd = Quiq::FFmpeg->new;
    $cmd->addInput('img/*.jpg');
    $self->is($cmd->command,q|-i 'img/*.jpg'|);
}
    

# -----------------------------------------------------------------------------

sub test_addFilter : Test(1) {
    my $self = shift;

    my $cmd = Quiq::FFmpeg->new;
    $cmd->addFilter(-vf=>['crop=1440:1080','scale=720*a:720'],',');
    $self->is($cmd->command,q|-vf 'crop=1440:1080,scale=720*a:720'|);
}
    

# -----------------------------------------------------------------------------

sub test_addStartStop : Test(3) {
    my $self = shift;
    
    my $cmd = Quiq::FFmpeg->new;
    $cmd->addStartStop(5.5);
    $self->is($cmd->command,q|-ss 5.5|);

    $cmd = Quiq::FFmpeg->new;
    $cmd->addStartStop(undef,20.5);
    $self->is($cmd->command,q|-t 20.5|);

    $cmd = Quiq::FFmpeg->new;
    $cmd->addStartStop(5.5,20.5);
    $self->is($cmd->command,q|-ss 5.5 -t 15|);
}
    

# -----------------------------------------------------------------------------

sub test_addBitrate : Test(2) {
    my $self = shift;
    
    my $cmd = Quiq::FFmpeg->new;
    $cmd->addBitrate(undef);
    $self->is($cmd->command,'');

    $cmd = Quiq::FFmpeg->new;
    $cmd->addBitrate(10000);
    $self->is($cmd->command,q|-b 10000k|);
}
    

# -----------------------------------------------------------------------------

sub test_addOutput : Test(1) {
    my $self = shift;
    
    my $cmd = Quiq::FFmpeg->new;
    $cmd->addOutput('GOPR1409-linus-rakete-1920x1080-000-010.mp4');
    $self->is($cmd->command,q|'GOPR1409-linus-rakete-1920x1080-000-010.mp4'|);
}
    

# -----------------------------------------------------------------------------

sub test_addString : Test(1) {
    my $self = shift;
    
    my $cmd = Quiq::FFmpeg->new;
    $cmd->addString('ffplay');
    $cmd->addString('-autoexit');
    $self->is($cmd->command,q|ffplay -autoexit|);
}
    

# -----------------------------------------------------------------------------

sub test_prependString : Test(1) {
    my $self = shift;
    
    my $cmd = Quiq::FFmpeg->new;
    $cmd->addOption('-autoexit');
    $cmd->prependString('ffplay');
    $self->is($cmd->command,q|ffplay -autoexit|);
}
    

# -----------------------------------------------------------------------------

sub test_cropFilter : Test(2) {
    my $self = shift;
    
    my $cmd = Quiq::FFmpeg->new;
    
    my $str = $cmd->cropFilter(1280,720);
    $self->is($str,q|crop=1280:720|);

    $str = $cmd->cropFilter(1280,720,240,0);
    $self->is($str,q|crop=1280:720:240:0|);
}
    

# -----------------------------------------------------------------------------

sub test_scaleFilter : Test(3) {
    my $self = shift;
    
    my $cmd = Quiq::FFmpeg->new;
    
    my $str = $cmd->scaleFilter(1280,720);
    $self->is($str,q|scale=1280:720|);

    $str = $cmd->scaleFilter("1280:720");
    $self->is($str,q|scale=1280:720|);

    my @filter;
    push @filter,$cmd->scaleFilter(undef);
    $self->isDeeply(\@filter,[]);
}
    

# -----------------------------------------------------------------------------

sub test_fpsFilter : Test(2) {
    my $self = shift;
    
    my $cmd = Quiq::FFmpeg->new;
    
    my $str = $cmd->fpsFilter(24);
    $self->is($str,q|fps=24|);

    my @filter;
    push @filter,$cmd->fpsFilter(undef);
    $self->isDeeply(\@filter,[]);
}
    

# -----------------------------------------------------------------------------

sub test_framestepFilter : Test(2) {
    my $self = shift;
    
    my $cmd = Quiq::FFmpeg->new;
    
    my $str = $cmd->framestepFilter(4);
    $self->is($str,q|framestep=4|);

    my @filter;
    push @filter,$cmd->framestepFilter(undef);
    $self->isDeeply(\@filter,[]);
}
    

# -----------------------------------------------------------------------------

sub test_imagesToVideo : Test(1) {
    my $self = shift;

    my $verbose = 0; # MEMO: auf 1 setzen, um Code+Resultat zu sehen
    
    my $exa = Quiq::ExampleCode->new(
        -fileHandle => \*STDERR,
        -verbose => $verbose,
    );

    # Ohne Optionen
    
    my $cmd = $exa->execute(q|
            Quiq::FFmpeg->imagesToVideo('img/*.jpg','img.mp4');
        |,
        -asStringCallback => sub {
            my ($cmd) = @_;
            return $cmd->command;
        },
    );
    my $regex = q|-framerate 8 -f image2 -pattern_type glob|.
        q| -i 'img/\*.jpg' -vf 'fps=24,format=yuv420p'|.
        q| -b:v 60000k 'img.mp4'|;
    $self->like($cmd->command,qr|$regex|);
}

# -----------------------------------------------------------------------------

sub test_videoToImages : Test(3) {
    my $self = shift;

    my $verbose = 0; # MEMO: auf 1 setzen, um Code+Resultat zu sehen
    
    my $exa = Quiq::ExampleCode->new(
        -fileHandle => \*STDERR,
        -verbose => $verbose,
    );

    # Ohne Optionen
    
    my $cmd = $exa->execute(q|
            Quiq::FFmpeg->videoToImages('video.mp4','img');
        |,
        -asStringCallback => sub {
            my ($cmd) = @_;
            return $cmd->command;
        },
    );
    $self->like($cmd->command,qr|^ffmpeg.*-i 'video.mp4'.*'img/%06d.jpg'|);

    # Video-Seitenverhältnis 16:9 zu Bild-Seitenverhältnis 4:3 wandeln
    
    $cmd = $exa->execute(q|
            Quiq::FFmpeg->videoToImages('video.mp4','img',
                -aspectRatio => '4:3',
            );
        |,
        -asStringCallback => sub {
            my ($cmd) = @_;
            return $cmd->command;
        },
    );
    $self->like($cmd->command,qr|^ffmpeg.*-vf 'crop=ih/3\*4:ih'|);

    # Alle Optionen

    $cmd = $exa->execute(q|
            Quiq::FFmpeg->videoToImages('video.mp4','img',
                -aspectRatio => '4:3',
                -framestep => 6,
                -start => 3,
                -stop => 10,
            );
        |,
        -asStringCallback => sub {
            my ($cmd) = @_;
            return $cmd->command;
        },
    );
    $self->like($cmd->command,qr|^ffmpeg.*-vf 'framestep=6,crop=ih/3\*4:ih'|);
}

# -----------------------------------------------------------------------------

sub test_videoInfo : Test(1) {
    my $self = shift;

    my $verbose = 0; # MEMO: auf 1 setzen, um Code+Resultat zu sehen
    
    my $exa = Quiq::ExampleCode->new(
        -fileHandle => \*STDERR,
        -verbose => $verbose,
    );

    # Kommando
    
    my $cmd = $exa->execute(q|
            Quiq::FFmpeg->videoInfo('video.mp4');
        |,
        -asStringCallback => sub {
            my ($cmd) = @_;
            return $cmd->command;
        },
    );
    $self->like($cmd->command,qr|^ffprobe|);
}

# -----------------------------------------------------------------------------

package main;
Quiq::FFmpeg::Test->runTests;

# eof
