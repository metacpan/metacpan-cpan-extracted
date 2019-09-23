#!/usr/bin/env perl

package Quiq::TimeLapse::File::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::TimeLapse::File');
}

# -----------------------------------------------------------------------------

sub test_new : Test(5) {
    my $self = shift;

    # my $testDir = $self->testDir;
    # my $file = "$testDir/A/img/000047-640x360.jpg";

    my $testDir = $self->testDir;
    my $file = $self->testPath(
        't/data/image/A/img/000047-640x360.jpg');

    my $img = Quiq::TimeLapse::File->new($file);
    $self->is(ref($img),'Quiq::TimeLapse::File');

    my $val = $img->path;
    $self->is($val,$file);

    my $name = $img->filename;
    $self->is($name,'000047-640x360.jpg');

    my $ext = $img->extension;
    $self->is($ext,'jpg');

    my $x = $img->number;
    $self->is($x,47);

    $self->set(img=>$img);

    return;
}

# -----------------------------------------------------------------------------

sub test_number : Test(2) {
    my $self = shift;

    my $img = $self->get('img');

    my $x = $img->number;
    $self->is("$x",'47');
    $self->is($x,47);

    return;
}

# -----------------------------------------------------------------------------

package main;
Quiq::TimeLapse::File::Test->runTests;

# eof
