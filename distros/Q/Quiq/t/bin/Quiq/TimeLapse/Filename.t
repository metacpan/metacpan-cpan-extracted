#!/usr/bin/env perl

package Quiq::TimeLapse::Filename::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::TimeLapse::Filename');
}

# -----------------------------------------------------------------------------

sub test_unitTest_1 : Test(7) {
    my $self = shift;

    my $file = '/my/image/dir/000219-3000x2250-G0080108.jpg';

    my $nam = Quiq::TimeLapse::Filename->new($file);
    $self->is(ref($nam),'Quiq::TimeLapse::Filename');

    my $n = $nam->number;
    $self->is($n,219);
    
    my $width = $nam->width;
    $self->is($width,3000);
    
    my $height = $nam->height;
    $self->is($height,2250);
    
    my $ext = $nam->extension;
    $self->is($ext,'jpg');
    
    my $text = $nam->text;
    $self->is($text,'G0080108');

    my $filename = $nam->asString;
    $self->is($filename,'000219-3000x2250-G0080108.jpg');
        
    return;
}

# -----------------------------------------------------------------------------

sub test_unitTest_2: Test(7) {
    my $self = shift;

    my $file = '/my/image/dir/000219-3000x2250.jpg';

    my $nam = Quiq::TimeLapse::Filename->new($file);
    $self->is(ref($nam),'Quiq::TimeLapse::Filename');

    my $n = $nam->number;
    $self->is($n,219);
    
    my $width = $nam->width;
    $self->is($width,3000);
    
    my $height = $nam->height;
    $self->is($height,2250);
    
    my $ext = $nam->extension;
    $self->is($ext,'jpg');
    
    my $text = $nam->text;
    $self->is($text,'');
    
    my $filename = $nam->asString;
    $self->is($filename,'000219-3000x2250.jpg');
        
    return;
}

# -----------------------------------------------------------------------------

sub test_unitTest_3 : Test(7) {
    my $self = shift;

    my $nam = Quiq::TimeLapse::Filename->new(219,3000,2250,'jpg',-text=>'G0080108');
    $self->is(ref($nam),'Quiq::TimeLapse::Filename');

    my $n = $nam->number;
    $self->is($n,219);
    
    my $width = $nam->width;
    $self->is($width,3000);
    
    my $height = $nam->height;
    $self->is($height,2250);
    
    my $ext = $nam->extension;
    $self->is($ext,'jpg');
    
    my $text = $nam->text;
    $self->is($text,'G0080108');
    
    my $filename = $nam->asString;
    $self->is($filename,'000219-3000x2250-G0080108.jpg');
        
    return;
}

# -----------------------------------------------------------------------------

sub test_unitTest_4 : Test(7) {
    my $self = shift;

    my $nam = Quiq::TimeLapse::Filename->new(219,3000,2250,'jpg');
    $self->is(ref($nam),'Quiq::TimeLapse::Filename');

    my $n = $nam->number;
    $self->is($n,219);
    
    my $width = $nam->width;
    $self->is($width,3000);
    
    my $height = $nam->height;
    $self->is($height,2250);
    
    my $ext = $nam->extension;
    $self->is($ext,'jpg');
    
    my $text = $nam->text;
    $self->is($text,'');
    
    my $filename = $nam->asString;
    $self->is($filename,'000219-3000x2250.jpg');
        
    return;
}

# -----------------------------------------------------------------------------

package main;
Quiq::TimeLapse::Filename::Test->runTests;

# eof
