#!/usr/bin/env perl

package Prty::ExampleCode::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use utf8;

use Prty::FFmpeg;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::ExampleCode');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(2) {
    my $self = shift;

    # MEMO: auf 1 setzen, um auf STDERR Code+Resultat zu sehen
    my $verbose = 0;
    
    # 1) Wertrückgabe
        
    my $exa = Prty::ExampleCode->new(
        -fileHandle=>\*STDERR,
        -verbose=>$verbose,
    );

    my $cmd = $exa->execute(q|
            Prty::FFmpeg->videoToImages('video.mp4','img');
        |,
    );
    $self->like($cmd->command,qr/^ffmpeg/);
    
    # 2) Rückgabe Objekt
    
    $exa = Prty::ExampleCode->new(
        -fileHandle=>\*STDERR,
        -objectReturn=>1,
        -verbose=>0,
    );
    
    my $obj = $exa->execute(q|
        Prty::FFmpeg->videoToImages('video.mp4','img',
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
Prty::ExampleCode::Test->runTests;

# eof
