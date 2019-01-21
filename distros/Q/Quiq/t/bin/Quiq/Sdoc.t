#!/usr/bin/env perl

package Quiq::Sdoc::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sdoc');
}

# -----------------------------------------------------------------------------

sub test_new : Test(1) {
    my $self = shift;

    my $gen = Quiq::Sdoc->new(indentation=>2);
    
    my $val = $gen->indentation;
    $self->is($val,2);
}

# -----------------------------------------------------------------------------

sub test_code : Test(2) {
    my $self = shift;

    my $gen = Quiq::Sdoc->new;
    
    my $str = $gen->code;
    $self->is($str,'');

    $str = $gen->code("Dies ist\nein Test\n");
    $self->is($str,"    Dies ist\n    ein Test\n\n");
}

# -----------------------------------------------------------------------------

sub test_comment : Test(2) {
    my $self = shift;

    my $gen = Quiq::Sdoc->new;
    
    my $str = $gen->comment('Ein Test');
    $self->is($str,"# Ein Test\n\n");

    $str = $gen->comment("Dies ist\nein Test\n");
    $self->is($str,"# Dies ist\n# ein Test\n\n");
}

# -----------------------------------------------------------------------------

sub test_document : Test(1) {
    my $self = shift;

    my $gen = Quiq::Sdoc->new(
        indentation=>2,
    );
    
    my $str = $gen->document(
        title=>'my-program',
        utf8=>'yes',
    );
    $self->is($str,qq|%Document:\n  title="my-program"\n  utf8="yes"\n\n|);
}

# -----------------------------------------------------------------------------

sub test_paragraph : Test(2) {
    my $self = shift;

    my $gen = Quiq::Sdoc->new;
    
    my $str = $gen->paragraph;
    $self->is($str,'');

    $str = $gen->paragraph("Dies ist\nein Test\n");
    $self->is($str,"Dies ist\nein Test\n\n");
}

# -----------------------------------------------------------------------------

sub test_table : Test(3) {
    my $self = shift;

    my $gen = Quiq::Sdoc->new(
        indentation=>2,
    );

    # Leere Tabelle

    my $str = $gen->table(undef);
    $self->is($str,'');

    $str = $gen->table('');
    $self->is($str,'');

    # Tabelle

    my $res = '
        %Table:
          P C O
          - - -
          V T R
          V V R
          J T R
          J T W
          J V R
        .
    ';
    
    $str = $gen->table('
        P C O
        - - -
        V T R
        V V R
        J T R
        J T W
        J V R
    ');
    $self->is(Quiq::Unindent->trim($str),Quiq::Unindent->trim($res));
}

# -----------------------------------------------------------------------------

sub test_tableOfContents : Test(1) {
    my $self = shift;

    my $gen = Quiq::Sdoc->new;
    
    my $str = $gen->tableOfContents(
        maxDepth=>3,
    );
    $self->is($str,qq|%TableOfContents:\n    maxDepth="3"\n\n|);
}

# -----------------------------------------------------------------------------

sub test_section : Test(1) {
    my $self = shift;

    my $gen = Quiq::Sdoc->new;
    
    my $str = $gen->section(2,'Test',"Ein\nTest");
    $self->is($str,"== Test\n\nEin\nTest\n\n");
}

# -----------------------------------------------------------------------------

sub test_definitionList : Test(4) {
    my $self = shift;

    my $gen = Quiq::Sdoc->new;
    
    my $str = $gen->definitionList([['A','Eins'],['B','Zwei']]);
    $self->is($str,"[A]:\n    Eins\n\n[B]:\n    Zwei\n\n");

    $str = $gen->definitionList([A=>'Eins',B=>'Zwei']);
    $self->is($str,"[A]:\n    Eins\n\n[B]:\n    Zwei\n\n");

    $str = $gen->definitionList([['A:','Eins'],['B:','Zwei']]);
    $self->is($str,"[A:]\n    Eins\n\n[B:]\n    Zwei\n\n");

    $str = $gen->definitionList(['A:'=>'Eins','B:'=>'Zwei']);
    $self->is($str,"[A:]\n    Eins\n\n[B:]\n    Zwei\n\n");
}

# -----------------------------------------------------------------------------

sub test_eof : Test(1) {
    my $self = shift;

    my $gen = Quiq::Sdoc->new;
    
    my $str = $gen->eof;
    $self->is($str,"# eof\n");
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sdoc::Test->runTests;

# eof
