#!/usr/bin/env perl

package Quiq::Terminal::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Terminal');
}

# -----------------------------------------------------------------------------

sub test_askUser : Test(7) {
    my $self = shift;

    my ($in,$out);
    open IN,'<',\$in or die "$!\n";
    open OUT,'>',\$out or die "$!\n";

    local *STDIN = *IN;
    local *STDOUT = *OUT;

    $in = "4711\n";
    seek IN,0,0;
    $out = '';
    seek OUT,0,0;
    my $val = Quiq::Terminal->askUser('Id=');
    $self->is($out,'Id=',"Prompt: '$out'");
    $self->is($val,4711,"Wert: $val");

    $in = " 4711 \n";
    seek IN,0,0;
    $out = '';
    seek OUT,0,0;
    $val = Quiq::Terminal->askUser('Id=');
    $self->is($val,4711,"Wert (ohne Whitespace): $val");

    $in = "  \n";
    seek IN,0,0;
    $out = '';
    seek OUT,0,0;
    $val = Quiq::Terminal->askUser('Id=');
    $self->is($val,'',"Wert (leer)");

    $in = "4711\n";
    seek IN,0,0;
    $out = '';
    seek OUT,0,0;
    $val = Quiq::Terminal->askUser('Id=',-default=>4712);
    $self->is($out,'Id= (4712) ',"Prompt: '$out'");
    $self->is($val,4711,"Wert: $val");

    $in = "\n";
    seek IN,0,0;
    $out = '';
    seek OUT,0,0;
    $val = Quiq::Terminal->askUser('Id',-default=>4712);
    $self->is($val,4712,"Defaultwert: $val");
}

# -----------------------------------------------------------------------------

sub test_ansiEsc : Test(2) {
    my $self = shift;

    my $val = Quiq::Terminal->ansiEsc('black');
    $self->is($val,"\e[30m",'ansiEsc: black');

    $val = Quiq::Terminal->ansiEsc($val);
    $self->is($val,"\e[30m",'ansiEsc: black als Escape-Sequenz');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Terminal::Test->runTests;

# eof
