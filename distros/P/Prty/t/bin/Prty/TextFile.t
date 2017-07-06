#!/usr/bin/env perl

package Prty::TextFile::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::TextFile');
}

# -----------------------------------------------------------------------------

sub test_new : Test(1) {
    my $self = shift;

    my $doc = Prty::TextFile->new(\"Dies\nist\nein\nTest");
    $self->is(ref($doc),'Prty::TextFile');
}

# -----------------------------------------------------------------------------

sub test_lines : Test(2) {
    my $self = shift;

    my $doc = Prty::TextFile->new(\"Dies\nist\nein\nTest");

    my @arr = $doc->lines;
    $self->is(scalar(@arr),4,'lines: Liste der Zeilen');

    my $arr = $doc->lines;
    $self->is(scalar(@$arr),4,'lines: Referenz auf Liste der Zeilen');
}

# -----------------------------------------------------------------------------

sub test_dump : Test(1) {
    my $self = shift;

    my $doc = Prty::TextFile->new(\"Dies\nist\nein\nTest");

    my $str = $doc->dump;
    $self->is($str,"Dies\nist\nein\nTest\n",'dump: Defaultformat');
}

# -----------------------------------------------------------------------------

sub test_removeEmptyLines : Test(3) {
    my $self = shift;

    my $doc = Prty::TextFile->new(\"\n\nDies\nist\nein\nTest");

    $doc->removeEmptyLines;
    my @lines = $doc->lines;
    $self->is(scalar(@lines),4,'removeEmptyLines: Anzahl Zeilen');

    my $line = $doc->shiftLine;

    my $n = $line->number;
    $self->is($n,3,'removeEmptyLines: Zeilennummer');

    my $text = $line->text;
    $self->is($text,'Dies','removeEmptyLines: Text');
}

# -----------------------------------------------------------------------------

sub test_shiftLine : Test(2) {
    my $self = shift;

    my $doc = Prty::TextFile->new(\"Dies\nist\nein\nTest");
    my $line = $doc->shiftLine;

    my $n = $line->number;
    $self->is($n,1,'shiftLine: Zeilennummer');

    my $text = $line->text;
    $self->is($text,'Dies','shiftLine: Text');
}

# -----------------------------------------------------------------------------

package main;
Prty::TextFile::Test->runTests;

# eof
