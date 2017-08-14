#!/usr/bin/env perl

package Prty::TimeLapse::File::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::TimeLapse::File');
}

# -----------------------------------------------------------------------------

sub test_new : Test(5) {
    my $self = shift;

    # my $testDir = $self->testDir;
    # my $file = "$testDir/A/img/000047-640x360.jpg";

    my $testDir = $self->testDir;
    my $file = $self->testPath(
        't/data/image/A/img/000047-640x360.jpg');

    my $img = Prty::TimeLapse::File->new($file);
    $self->is(ref($img),'Prty::TimeLapse::File');

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
Prty::TimeLapse::File::Test->runTests;

# eof
