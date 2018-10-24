#!/usr/bin/env perl

package Prty::Sdoc::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc');
}

# -----------------------------------------------------------------------------

sub test_comment : Test(2) {
    my $self = shift;

    my $gen = Prty::Sdoc->new;
    
    my $str = $gen->comment('Ein Test');
    $self->is($str,"# Ein Test\n\n");

    $str = $gen->comment("Dies ist\nein Test\n");
    $self->is($str,"# Dies ist\n# ein Test\n\n");
}

# -----------------------------------------------------------------------------

sub test_document : Test(1) {
    my $self = shift;

    my $gen = Prty::Sdoc->new(
        indentation=>2,
    );
    
    my $str = $gen->document(
        title=>'my-program',
        utf8=>'yes',
    );
    $self->is($str,qq|%Document:\n  title="my-program"\n  utf8="yes"\n\n|);
}

# -----------------------------------------------------------------------------

sub test_tableOfContents : Test(1) {
    my $self = shift;

    my $gen = Prty::Sdoc->new;
    
    my $str = $gen->tableOfContents(
        maxDepth=>3,
    );
    $self->is($str,qq|%TableOfContents:\n    maxDepth="3"\n\n|);
}

# -----------------------------------------------------------------------------

sub test_section : Test(1) {
    my $self = shift;

    my $gen = Prty::Sdoc->new;
    
    my $str = $gen->section(2,'Test',"Ein\nTest");
    $self->is($str,"== Test\n\nEin\nTest\n\n");
}

# -----------------------------------------------------------------------------

sub test_definitionList : Test(4) {
    my $self = shift;

    my $gen = Prty::Sdoc->new;
    
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

    my $gen = Prty::Sdoc->new;
    
    my $str = $gen->eof;
    $self->is($str,"# eof\n");
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::Test->runTests;

# eof
