#!/usr/bin/env perl

package Prty::MediaWiki::Markup::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::MediaWiki::Markup');
}

# -----------------------------------------------------------------------------

sub test_code : Test(4) {
    my $self = shift;

    my $gen = Prty::MediaWiki::Markup->new;
    
    my $code = $gen->code(undef);
    $self->is($code,'');

    $code = $gen->code('');
    $self->is($code,'');

    $code = $gen->code("Dies ist\nein Test.\n");
    $self->is($code,"  <nowiki>Dies ist\n  ein Test.</nowiki>\n\n");

    $code = $gen->code(q~
        Dies ist
        ein Test.
    ~);
    $self->is($code,"  <nowiki>Dies ist\n  ein Test.</nowiki>\n\n");
}

# -----------------------------------------------------------------------------

sub test_comment : Test(4) {
    my $self = shift;

    my $gen = Prty::MediaWiki::Markup->new;
    
    my $code = $gen->comment(undef);
    $self->is($code,'');

    $code = $gen->comment('');
    $self->is($code,'');

    $code = $gen->comment("Dies ist ein Kommentar\n");
    $self->is($code,"<!-- Dies ist ein Kommentar -->\n\n");

    $code = $gen->comment(q~
        Dies ist
        ein Kommentar
    ~);
    $self->is($code,"<!--\n  Dies ist\n  ein Kommentar\n-->\n\n");
}

# -----------------------------------------------------------------------------

sub test_horizontalRule : Test(1) {
    my $self = shift;

    my $gen = Prty::MediaWiki::Markup->new;
    
    my $code = $gen->horizontalRule;
    $self->is($code,"----\n\n");
}

# -----------------------------------------------------------------------------

sub test_paragraph : Test(4) {
    my $self = shift;

    my $gen = Prty::MediaWiki::Markup->new;
    
    my $code = $gen->paragraph(undef);
    $self->is($code,'');

    $code = $gen->paragraph('');
    $self->is($code,'');

    $code = $gen->paragraph("Dies ist\nein Test.\n");
    $self->is($code,"Dies ist\nein Test.\n\n");

    $code = $gen->paragraph(q~
        Dies ist
        ein Test.
    ~);
    $self->is($code,"Dies ist\nein Test.\n\n");
}

# -----------------------------------------------------------------------------

sub test_section : Test(2) {
    my $self = shift;

    my $gen = Prty::MediaWiki::Markup->new;
    
    my $code = $gen->section(1,'Test');
    $self->is($code,"= Test =\n\n");

    $code = $gen->section(6,'Test');
    $self->is($code,"====== Test ======\n\n");
}

# -----------------------------------------------------------------------------

sub test_tableOfContents : Test(2) {
    my $self = shift;

    my $gen = Prty::MediaWiki::Markup->new;
    
    my $code = $gen->tableOfContents(0);
    $self->is($code,"__NOTOC__\n\n");

    $code = $gen->tableOfContents(1);
    $self->is($code,"__TOC__\n\n");
}

# -----------------------------------------------------------------------------

sub test_fmt : Test(5) {
    my $self = shift;

    my $gen = Prty::MediaWiki::Markup->new;
    
    my $code = $gen->fmt('xxx',undef);
    $self->is($code,'');

    $code = $gen->fmt('xxx','');
    $self->is($code,'');

    # comment

    $code = $gen->fmt('comment',"Dies ist\nein Kommentar\n");
    $self->is($code,'<!-- Dies ist ein Kommentar -->');

    $code = $gen->fmt('comment',q~
        Dies ist
        ein Kommentar
    ~);
    $self->is($code,'<!-- Dies ist ein Kommentar -->');

    # Unbekannter Typ -> Exception

    $code = eval{$gen->fmt('xxx','Test')};
    $self->like($@,qr/Unknown inline format/);
}

# -----------------------------------------------------------------------------

package main;
Prty::MediaWiki::Markup::Test->runTests;

# eof
