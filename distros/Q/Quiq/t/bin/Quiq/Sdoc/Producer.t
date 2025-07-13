#!/usr/bin/env perl

package Quiq::Sdoc::Producer::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sdoc::Producer');
}

# -----------------------------------------------------------------------------

sub test_new : Test(1) {
    my $self = shift;

    my $gen = Quiq::Sdoc::Producer->new(indentation=>2);
    
    my $val = $gen->indentation;
    $self->is($val,2);
}

# -----------------------------------------------------------------------------

sub test_code : Test(2) {
    my $self = shift;

    my $gen = Quiq::Sdoc::Producer->new;
    
    my $str = $gen->code;
    $self->is($str,'');

    $str = $gen->code("Dies ist\nein Test\n");
    $self->is($str,"    Dies ist\n    ein Test\n\n");
}

# -----------------------------------------------------------------------------

sub test_comment : Test(2) {
    my $self = shift;

    my $gen = Quiq::Sdoc::Producer->new;
    
    my $str = $gen->comment('Ein Test');
    $self->is($str,"# Ein Test\n\n");

    $str = $gen->comment("Dies ist\nein Test\n");
    $self->is($str,"# Dies ist\n# ein Test\n\n");
}

# -----------------------------------------------------------------------------

sub test_document : Test(1) {
    my $self = shift;

    my $gen = Quiq::Sdoc::Producer->new(
        indentation=>2,
    );
    
    my $str = $gen->document(
        title=>'my-program',
        utf8=>'yes',
    );
    $self->is($str,qq|%Document:\n  title="my-program"\n  utf8="yes"\n\n|);
}

# -----------------------------------------------------------------------------

sub test_format : Test(1) {
    my $self = shift;

    my $gen = Quiq::Sdoc::Producer->new;
    
    my $str = $gen->format(
        HTML => '<p>Hallo</p>',
        LaTeX => 'Hallo',
    );
    $self->is($str,Quiq::Unindent->string(q~
        %Format:
        @@HTML@@
        <p>Hallo</p>
        @@LaTeX@@
        Hallo
        .

    ~));
}

# -----------------------------------------------------------------------------

sub test_linkDefs : Test(1) {
    my $self = shift;

    my $gen = Quiq::Sdoc::Producer->new;
    
    my $str = $gen->link('fseitz.de',
        url => 'http://fseitz.de',
        target => 'home',
    );
    $self->is($str,'L{fseitz.de}');

    # $self->is($str,Quiq::Unindent->string(q~
    #     %Format:
    #     @@HTML@@
    #     <p>Hallo</p>
    #     @@LaTeX@@
    #     Hallo
    #     .
    # 
    # ~));
}

# -----------------------------------------------------------------------------

sub test_paragraph : Test(2) {
    my $self = shift;

    my $gen = Quiq::Sdoc::Producer->new;
    
    my $str = $gen->paragraph;
    $self->is($str,'');

    $str = $gen->paragraph("Dies ist\nein Test\n");
    $self->is($str,"Dies ist\nein Test\n\n");
}

# -----------------------------------------------------------------------------

sub test_segment : Test(1) {
    my $self = shift;

    my $expeted = 

    my $gen = Quiq::Sdoc::Producer->new;
    
    my $str = $gen->segment('red',
        html => '<span style="color: red">%s</span>',
        latex => '{\color{red}%s}',
        mediawiki => '<span style="color: red">%s</span>',
    );
    $str =~ s/\n+$/\n/;

    $self->isText($str,q~
    %Segment:
        name=red
        html='<span style="color: red">%s</span>'
        latex='{\color{red}%s}'
        mediawiki='<span style="color: red">%s</span>'
    ~);
}

# -----------------------------------------------------------------------------

sub test_table : Test(4) {
    my $self = shift;

    my $gen = Quiq::Sdoc::Producer->new;

    # Leere Tabelle

    my $str = $gen->table(undef);
    $self->is($str,'');

    $str = $gen->table('');
    $self->is($str,'');

    # Tabelle (Text)

    $str = $gen->table('
        P C O
        - - -
        V T R
        V V R
        J T R
        J T W
        J V R
    ');
    chomp $str;

    $self->isText($str,q~
        %Table:
        P C O
        - - -
        V T R
        V V R
        J T R
        J T W
        J V R
        .
    ~);

    # Tabelle (Titel und Zeilen)

    $str = $gen->table(['Integer','String','Float'],[
        [1,  'A',  76.253],
        [12, 'AB', 1.7   ],
        [123,'ABC',9999  ],
    ]);
    chomp $str;

    $self->isText($str,q~
        %Table:
        Integer String    Float
        ------- ------ --------
              1 A        76.253
             12 AB        1.700
            123 ABC    9999.000
        .
    ~);
}

# -----------------------------------------------------------------------------

sub test_tableOfContents : Test(1) {
    my $self = shift;

    my $gen = Quiq::Sdoc::Producer->new;
    
    my $str = $gen->tableOfContents(
        maxDepth => 3,
    );
    $self->is($str,qq|%TableOfContents:\n    maxDepth="3"\n\n|);
}

# -----------------------------------------------------------------------------

sub test_section : Test(2) {
    my $self = shift;

    my $gen = Quiq::Sdoc::Producer->new;
    
    my $str = $gen->section(2,'Test',"Ein\nTest");
    $self->is($str,"== Test\n\nEin\nTest\n\n");

    # Mit @keyVal

    $str = $gen->section(2,'Test',htmlFolding=>1,"Ein\nTest");
    $self->is($str,Quiq::Unindent->string(q~
        %Section:
            level="2"
            title="Test"
            htmlFolding="1"

        Ein
        Test

    ~));
}

# -----------------------------------------------------------------------------

sub test_definitionList : Test(4) {
    my $self = shift;

    my $gen = Quiq::Sdoc::Producer->new;
    
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

    my $gen = Quiq::Sdoc::Producer->new;
    
    my $str = $gen->eof;
    $self->is($str,"# eof\n");
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sdoc::Producer::Test->runTests;

# eof
