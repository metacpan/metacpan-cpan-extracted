#!/usr/bin/env perl

package Quiq::LineProcessor::Line::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::LineProcessor::Line');
}

# -----------------------------------------------------------------------------

sub test_new : Test(3) {
    my $self = shift;

    my $str = 'Na? Arbeiten?';
    my $n = 5;

    my $ln = Quiq::LineProcessor::Line->new($str,$n,\'[testfile]');
    $self->is(ref($ln),'Quiq::LineProcessor::Line');
    $self->is($ln->text,$str);
    $self->is($ln->number,$n);
}

# -----------------------------------------------------------------------------

sub test_text : Test(3) {
    my $self = shift;

    my $ln = Quiq::LineProcessor::Line->new('',1,\'[testfile]');
    my $str = $ln->text;
    $self->is($str,'',);

    $str = $ln->text('     ');
    $self->is($str,'',);

    $str = $ln->text('  abc  ');
    $self->is($str,'  abc');
}

# -----------------------------------------------------------------------------

sub test_number : Test(2) {
    my $self = shift;

    my $ln = Quiq::LineProcessor::Line->new('abc',1,\'[testfile]');
    my $n = $ln->number;
    $self->is($n,1);

    $ln = Quiq::LineProcessor::Line->new('abc',55,\'[testfile]');
    $n = $ln->number;
    $self->is($n,55);
}

# -----------------------------------------------------------------------------

sub test_isEmpty : Test(3) {
    my $self = shift;

    my $ln = Quiq::LineProcessor::Line->new('',1,\'[testfile]');
    my $bool = $ln->isEmpty;
    $self->is($bool,1);

    $ln = Quiq::LineProcessor::Line->new(0,1,\'[testfile]');
    $bool = $ln->isEmpty;
    $self->is($bool,0);

    $ln = Quiq::LineProcessor::Line->new('xxx',1,\'[testfile]');
    $bool = $ln->isEmpty;
    $self->is($bool,0);
}

# -----------------------------------------------------------------------------

sub test_indentation : Test(4) {
    my $self = shift;

    my $ln = Quiq::LineProcessor::Line->new('',1,\'[testfile]');
    my $n = $ln->indentation;
    $self->is($n,0);

    $ln = Quiq::LineProcessor::Line->new('   ',1,\'[testfile]');
    $n = $ln->indentation;
    $self->is($n,0);

    $ln = Quiq::LineProcessor::Line->new('    x x x',1,\'[testfile]');
    $n = $ln->indentation;
    $self->is($n,4);

    $ln = Quiq::LineProcessor::Line->new("\tx x x",1,\'[testfile]');
    $n = $ln->indentation;
    $self->is($n,1);
}

# -----------------------------------------------------------------------------

sub test_length : Test(2) {
    my $self = shift;

    my $ln = Quiq::LineProcessor::Line->new('',1,\'[testfile]');
    my $n = $ln->length;
    $self->is($n,0);

    $ln = Quiq::LineProcessor::Line->new('abc',1,\'[testfile]');
    $n = $ln->length;
    $self->is($n,3);
}

# -----------------------------------------------------------------------------

sub test_append : Test(1) {
    my $self = shift;

    my $str1 = 'Na? Arbeiten?';
    my $str2 = ' ja/nein/vielleicht';
    my $n = 5;

    my $ln = Quiq::LineProcessor::Line->new($str1,$n,\'[testfile]');
    $str1 .= $str2;
    $ln->append($str2);
    $self->is($ln->text,$str1);
}

# -----------------------------------------------------------------------------

sub test_trim : Test(1) {
    my $self = shift;

    my $ln = Quiq::LineProcessor::Line->new('    Ein Test.   ',1,\'[testfile]');
    $ln->trim;
    $self->is($ln->text,'Ein Test.');
}

# -----------------------------------------------------------------------------

sub test_unindent : Test(1) {
    my $self = shift;

    my $ln = Quiq::LineProcessor::Line->new('    Ein Test.',1,\'[testfile]');
    $ln->unindent(4);
    $self->is($ln->text,'Ein Test.');
}

# -----------------------------------------------------------------------------

sub test_dump : Test(3) {
    my $self = shift;

    my $line = 'Na? Arbeiten?';
    my $n = 5;

    my $ln = Quiq::LineProcessor::Line->new($line,$n,\'[testfile]');

    my $str = $ln->dump;
    $self->is($str,"$line\n");

    $str = $ln->dump(0);
    $self->is($str,"$line\n");

    $str = $ln->dump(1);
    $self->is($str,sprintf("%4d: %s\n",$n,$line));
}

# -----------------------------------------------------------------------------

package main;
Quiq::LineProcessor::Line::Test->runTests;

# eof
