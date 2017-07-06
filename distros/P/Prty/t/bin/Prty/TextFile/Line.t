#!/usr/bin/env perl

package Prty::TextFile::Line::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::TextFile::Line');
}

# -----------------------------------------------------------------------------

sub test_new : Test(3) {
    my $self = shift;

    my $str = 'Na? Arbeiten?';
    my $n = 5;

    my $ln = Prty::TextFile::Line->new($str,$n);
    $self->is(ref($ln),'Prty::TextFile::Line','new: Klassenname');
    $self->is($ln->text,$str,'new: text');
    $self->is($ln->number,$n,'new: number');
}

# -----------------------------------------------------------------------------

sub test_text : Test(3) {
    my $self = shift;

    my $ln = Prty::TextFile::Line->new('',1);
    my $str = $ln->text;
    $self->is($str,'','text: Leerzeile');

    $str = $ln->text('     ');
    $self->is($str,'','text: Whitespace-Zeile');

    $str = $ln->text('  abc  ');
    $self->is($str,'  abc','text: Whitespace-Zeile');
}

# -----------------------------------------------------------------------------

sub test_number : Test(2) {
    my $self = shift;

    my $ln = Prty::TextFile::Line->new('abc',1);
    my $n = $ln->number;
    $self->is($n,1,'number: 1');

    $ln = Prty::TextFile::Line->new('abc',55);
    $n = $ln->number;
    $self->is($n,55,'number: 55');
}

# -----------------------------------------------------------------------------

sub test_append : Test(1) {
    my $self = shift;

    my $str1 = 'Na? Arbeiten?';
    my $str2 = ' ja/nein/vielleicht';
    my $n = 5;

    my $ln = Prty::TextFile::Line->new($str1,$n);
    $str1 .= $str2;
    $ln->append($str2);
    $self->is($ln->text,$str1,'append');
}

# -----------------------------------------------------------------------------

sub test_dump : Test(3) {
    my $self = shift;

    my $line = 'Na? Arbeiten?';
    my $n = 5;

    my $ln = Prty::TextFile::Line->new($line,$n);

    my $str = $ln->dump;
    $self->is($str,"$line\n",'dump: Defaultformat');

    $str = $ln->dump(0);
    $self->is($str,"$line\n",'dump: Format 0');

    $str = $ln->dump(1);
    $self->is($str,sprintf("%4d: %s\n",$n,$line),'dump: Format 1');
}

# -----------------------------------------------------------------------------

sub test_isEmpty : Test(3) {
    my $self = shift;

    my $ln = Prty::TextFile::Line->new('',1);
    my $bool = $ln->isEmpty;
    $self->is($bool,1,'isEmpty: leer');

    $ln = Prty::TextFile::Line->new(0,1);
    $bool = $ln->isEmpty;
    $self->is($bool,0,'isEmpty: 0');

    $ln = Prty::TextFile::Line->new('xxx',1);
    $bool = $ln->isEmpty;
    $self->is($bool,0,'isEmpty: nicht-leer');
}

# -----------------------------------------------------------------------------

sub test_indentation : Test(4) {
    my $self = shift;

    my $ln = Prty::TextFile::Line->new('',1);
    my $n = $ln->indentation;
    $self->is($n,0,'indentation: Leerzeile');

    $ln = Prty::TextFile::Line->new('   ',1);
    $n = $ln->indentation;
    $self->is($n,0,'indentation: nur Leerzeichen');

    $ln = Prty::TextFile::Line->new('    x x x',1);
    $n = $ln->indentation;
    $self->is($n,4,'indentation: SPACE-Einrückung');

    $ln = Prty::TextFile::Line->new("\tx x x",1);
    $n = $ln->indentation;
    $self->is($n,1,'indentation: TAB-Einrückung');
}

# -----------------------------------------------------------------------------

sub test_length : Test(2) {
    my $self = shift;

    my $ln = Prty::TextFile::Line->new('',1);
    my $n = $ln->length;
    $self->is($n,0,'length: Leerzeile');

    $ln = Prty::TextFile::Line->new('abc',1);
    $n = $ln->length;
    $self->is($n,3,'length: nur Leerzeichen');
}

# -----------------------------------------------------------------------------

package main;
Prty::TextFile::Line::Test->runTests;

# eof
