#!/usr/bin/env perl

package Prty::LineProcessor::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::LineProcessor');
}

# -----------------------------------------------------------------------------

sub test_new : Test(1) {
    my $self = shift;

    my $par = Prty::LineProcessor->new(\"Dies\nist\nein\nTest");
    $self->is(ref($par),'Prty::LineProcessor');
}

# -----------------------------------------------------------------------------

sub test_lines : Test(2) {
    my $self = shift;

    my $par = Prty::LineProcessor->new(\"Dies\nist\nein\nTest");

    my @arr = $par->lines;
    $self->is(scalar(@arr),4,'lines: Liste der Zeilen');

    my $arr = $par->lines;
    $self->is(scalar(@$arr),4,'lines: Referenz auf Liste der Zeilen');
}

# -----------------------------------------------------------------------------

sub test_shiftLine : Test(2) {
    my $self = shift;

    my $par = Prty::LineProcessor->new(\"Dies\nist\nein\nTest");
    my $line = $par->shiftLine;

    my $n = $line->number;
    $self->is($n,1,'shiftLine: Zeilennummer');

    my $text = $line->text;
    $self->is($text,'Dies','shiftLine: Text');
}

# -----------------------------------------------------------------------------

sub test_removeEmptyLines : Test(3) {
    my $self = shift;

    my $par = Prty::LineProcessor->new(\"\n\nDies\nist\nein\nTest");

    $par->removeEmptyLines;
    my @lines = $par->lines;
    $self->is(scalar(@lines),4,'removeEmptyLines: Anzahl Zeilen');

    my $line = $par->shiftLine;

    my $n = $line->number;
    $self->is($n,3,'removeEmptyLines: Zeilennummer');

    my $text = $line->text;
    $self->is($text,'Dies','removeEmptyLines: Text');
}

# -----------------------------------------------------------------------------

sub test_dump : Test(1) {
    my $self = shift;

    my $par = Prty::LineProcessor->new(\"Dies\nist\nein\nTest");

    my $str = $par->dump;
    $self->is($str,"Dies\nist\nein\nTest\n",'dump: Defaultformat');
}

# -----------------------------------------------------------------------------

package main;
Prty::LineProcessor::Test->runTests;

# eof
