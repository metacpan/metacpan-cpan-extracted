#!/usr/bin/env perl

package Quiq::ExampleCode::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

use Quiq::FFmpeg;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ExampleCode');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(2) {
    my $self = shift;

    # MEMO: auf 1 setzen, um auf STDERR Code+Resultat zu sehen
    my $verbose = 0;
    
    # 1) Wertrückgabe
        
    my $exa = Quiq::ExampleCode->new(
        -fileHandle=>\*STDERR,
        -verbose=>$verbose,
    );

    my $cmd = $exa->execute(q|
            Quiq::FFmpeg->videoToImages('video.mp4','img');
        |,
    );
    $self->like($cmd->command,qr/^ffmpeg/);
    
    # 2) Rückgabe Objekt
    
    $exa = Quiq::ExampleCode->new(
        -fileHandle=>\*STDERR,
        -objectReturn=>1,
        -verbose=>0,
    );
    
    my $obj = $exa->execute(q|
        Quiq::FFmpeg->videoToImages('video.mp4','img',
            -aspectRatio=>'4:3',
            -framestep=>6,
            -start=>3,
            -stop=>10,
        );
    |);
    $cmd = $obj->result;
    if ($verbose) {
        warn $obj->code,"\n=>\n$cmd\n";
    }
    $self->like($cmd->command,qr/^ffmpeg/);
}

# -----------------------------------------------------------------------------

package main;
Quiq::ExampleCode::Test->runTests;

# eof
