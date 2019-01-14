#!/usr/bin/env perl

package Quiq::MediaWiki::Markup::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::MediaWiki::Markup');
}

# -----------------------------------------------------------------------------

sub test_code : Test(4) {
    my $self = shift;

    my $gen = Quiq::MediaWiki::Markup->new;
    
    my $code = $gen->code(undef);
    $self->is($code,'');

    $code = $gen->code('');
    $self->is($code,'');

    $code = $gen->code("Dies ist\nein Test.\n");
    $self->is($code,"<pre>Dies ist\nein Test.</pre>\n\n");

    $code = $gen->code(q~
        Dies ist
        ein Test.
    ~);
    $self->is($code,"<pre>Dies ist\nein Test.</pre>\n\n");
}

# -----------------------------------------------------------------------------

sub test_comment : Test(4) {
    my $self = shift;

    my $gen = Quiq::MediaWiki::Markup->new;
    
    my $code = $gen->comment(undef);
    $self->is($code,'');

    $code = $gen->comment('');
    $self->is($code,'');

    $code = $gen->comment("Dies ist ein Kommentar\n");
    $self->is($code,"<!-- Dies ist ein Kommentar -->\n");

    $code = $gen->comment(q~
        Dies ist
        ein Kommentar
    ~);
    $self->is($code,"<!--\n  Dies ist\n  ein Kommentar\n-->\n");
}

# -----------------------------------------------------------------------------

sub test_horizontalRule : Test(1) {
    my $self = shift;

    my $gen = Quiq::MediaWiki::Markup->new;
    
    my $code = $gen->horizontalRule;
    $self->is($code,"----\n\n");
}

# -----------------------------------------------------------------------------

sub test_item : Test(5) {
    my $self = shift;

    my $gen = Quiq::MediaWiki::Markup->new;
    
    my $code = $gen->item('*','Apfel');
    $self->is($code,"* Apfel\n");

    $code = $gen->item('#','Birne');
    $self->is($code,"# Birne\n");

    $code = $gen->item(';',P=>'Pflaume');
    $self->is($code,"; P : Pflaume\n");

    $code = $gen->item('*#*','Quitte');
    $self->is($code,"*#* Quitte\n");

    $code = $gen->item('#',"* Apfel\n* Birne\n* Pflaume");
    $self->is($code,"#* Apfel\n#* Birne\n#* Pflaume\n");
}

# -----------------------------------------------------------------------------

sub test_paragraph : Test(4) {
    my $self = shift;

    my $gen = Quiq::MediaWiki::Markup->new;
    
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

    my $gen = Quiq::MediaWiki::Markup->new;
    
    my $code = $gen->section(1,'Test');
    $self->is($code,"= Test =\n\n");

    $code = $gen->section(6,'Test');
    $self->is($code,"====== Test ======\n\n");
}

# -----------------------------------------------------------------------------

sub test_table_0 : Test(1) {
    my $self = shift;

    my $code = Quiq::MediaWiki::Markup->new->table;
    $self->is($code,'');
}

# -----------------------------------------------------------------------------

sub test_table_1 : Test(1) {
    my $self = shift;

    my $code = Quiq::MediaWiki::Markup->new->table(
        alignments => ['left','right','center'],
        caption => 'Eine Tabelle',
        titles => ['L','R','Z'],
        rows => [
            ['A',1,'ABCDEFG'],
            ['AB',12,'HIJKL'],
            ['ABC',123,'MNO'],
            ['ABCD',1234,'P'],
        ],            
    );
    $self->is($code,Quiq::Unindent->string(q~
        {| class="wikitable"
        |+ style="caption-side: bottom; font-weight: normal"|Eine Tabelle
        |-
        ! style="background-color: #e8e8e8; text-align: left" |L
        ! style="background-color: #e8e8e8; text-align: right" |R
        ! style="background-color: #e8e8e8" |Z
        |-
        | style="background-color: #ffffff" |A
        | style="background-color: #ffffff; text-align: right" |1
        | style="background-color: #ffffff; text-align: center" |ABCDEFG
        |-
        | style="background-color: #ffffff" |AB
        | style="background-color: #ffffff; text-align: right" |12
        | style="background-color: #ffffff; text-align: center" |HIJKL
        |-
        | style="background-color: #ffffff" |ABC
        | style="background-color: #ffffff; text-align: right" |123
        | style="background-color: #ffffff; text-align: center" |MNO
        |-
        | style="background-color: #ffffff" |ABCD
        | style="background-color: #ffffff; text-align: right" |1234
        | style="background-color: #ffffff; text-align: center" |P
        |}

    ~));
}

# -----------------------------------------------------------------------------

sub test_tableOfContents : Test(2) {
    my $self = shift;

    my $gen = Quiq::MediaWiki::Markup->new;
    
    my $code = $gen->tableOfContents(0);
    $self->is($code,"__NOTOC__\n\n");

    $code = $gen->tableOfContents(1);
    $self->is($code,"__TOC__\n\n");
}

# -----------------------------------------------------------------------------

sub test_fmt : Test(5) {
    my $self = shift;

    my $gen = Quiq::MediaWiki::Markup->new;
    
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

sub test_indent : Test(2) {
    my $self = shift;

    my $gen = Quiq::MediaWiki::Markup->new;

    my $code = $gen->indent(0);
    $self->is($code,'');
    
    $code = $gen->indent(2);
    $self->is($code,'::');
}

# -----------------------------------------------------------------------------

sub test_link : Test(2) {
    my $self = shift;

    my $gen = Quiq::MediaWiki::Markup->new;

    my $code = $gen->link('internal','Transaktionssicherheit',
            'Abschnitt Transaktiossicherheit');
    $self->is($code,'[[#Transaktionssicherheit'.
        '|Abschnitt Transaktiossicherheit]]');
    
    $code = $gen->link('external','http::/fseitz.de/',
        'Homepage Frank Seitz');
    $self->is($code,'[http::/fseitz.de/ Homepage Frank Seitz]');
}

# -----------------------------------------------------------------------------

package main;
Quiq::MediaWiki::Markup::Test->runTests;

# eof
