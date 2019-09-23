#!/usr/bin/env perl

package Quiq::AsciiTable::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::AsciiTable');
}

# -----------------------------------------------------------------------------

sub test_unitTest_0 : Test(1) {
    my $self = shift;

    # Keine Tabelle

    my $tab = eval {Quiq::AsciiTable->new("A\nB\nC\n")};
    $self->like($@,qr/No table/);
}

# -----------------------------------------------------------------------------

sub test_unitTest_Minimal : Test(9) {
    my $self = shift;

    # Tabelle mit Titel und Zellenausrichtung

    my $table = q~
        T
        -
        C
    ~;

    my $tab = Quiq::AsciiTable->new($table);
    $self->is(ref($tab),'Quiq::AsciiTable');

    my $rangeA = $tab->rangeA;
    $self->isDeeply($rangeA,[
        [1,0,1],
    ]);

    my $width = $tab->width;
    $self->is($width,1);

    my $multiLine = $tab->multiLine;
    $self->is($multiLine,0);

    my $titleA = $tab->titles;
    $self->isDeeply($titleA,['T']);

    my $alignA = $tab->alignments;
    $self->isDeeply($alignA,['l']);

    my $rowA = $tab->rows;
    $self->is(scalar(@$rowA),1);
    $self->isDeeply($rowA,[
        ['C'],
    ]);

    my $str = $tab->asText;
    $self->is($str,
        "T\n".
        "-\n".
        "C\n"
    );

    return;
}

# -----------------------------------------------------------------------------

sub test_unitTest_SingleLine : Test(9) {
    my $self = shift;

    # Tabelle mit Titel und Zellenausrichtung

    my $table = q~
        Right Left Center
        ----- ---- ------
            1 A      A
           21 AB    AB
          321 ABC   ABC
    ~;

    my $tab = Quiq::AsciiTable->new($table);
    $self->is(ref($tab),'Quiq::AsciiTable');

    my $width = $tab->width;
    $self->is($width,3);

    my $rangeA = $tab->rangeA;
    $self->isDeeply($rangeA,[
        [1,0,5],
        [0,5,1],
        [1,6,4],
        [0,10,1],
        [1,11,6],
    ]);

    my $multiLine = $tab->multiLine;
    $self->is($multiLine,0);

    my $titleA = $tab->titles;
    $self->isDeeply($titleA,[qw/Right Left Center/]);

    my $alignA = $tab->alignments;
    $self->isDeeply($alignA,['r','l','c']);

    my $rowA = $tab->rows;
    $self->is(scalar(@$rowA),3);
    $self->isDeeply($rowA,[
        ['1',  'A',  'A'],
        ['21', 'AB', 'AB'],
        ['321','ABC','ABC'],
    ]);

    my $str = $tab->asText;
    $self->is($str,
        "Right Left Center\n".
        "----- ---- ------\n".
        "    1 A      A\n".
        "   21 AB    AB\n".
        "  321 ABC   ABC\n"
    );
}

# -----------------------------------------------------------------------------

sub test_unitTest_NoTitles : Test(9) {
    my $self = shift;

    # Tabelle ohne Titel

    my $table = q~
        ----- ---- ------
            1 A      A
           21 AB    AB
          321 ABC   ABC
    ~;

    my $tab = Quiq::AsciiTable->new($table);
    $self->is(ref($tab),'Quiq::AsciiTable');

    my $width = $tab->width;
    $self->is($width,3);

    my $rangeA = $tab->rangeA;
    $self->isDeeply($rangeA,[
        [1,0,5],
        [0,5,1],
        [1,6,4],
        [0,10,1],
        [1,11,6],
    ]);

    my $multiLine = $tab->multiLine;
    $self->is($multiLine,0);

    my $titleA = $tab->titles;
    $self->isDeeply($titleA,[]);

    my $alignA = $tab->alignments;
    $self->isDeeply($alignA,['r','l','c']);

    my $rowA = $tab->rows;
    $self->is(scalar(@$rowA),3);
    $self->isDeeply($rowA,[
        ['1',  'A',  'A'],
        ['21', 'AB', 'AB'],
        ['321','ABC','ABC'],
    ]);

    my $str = $tab->asText;
    $self->is($str,
        "----- ---- ------\n".
        "    1 A      A\n".
        "   21 AB    AB\n".
        "  321 ABC   ABC\n"
    );
}

# -----------------------------------------------------------------------------

sub test_unitTest_MultiLineTitle : Test(8) {
    my $self = shift;

    # Tabelle mit Titel und Zellenausrichtung

    my $table = q~
          Right Left    Centered
        Aligned Aligned  Header
        ------- ------- --------
              1 A          A
             21 AB         AB
            321 ABC        ABC
    ~;

    my $tab = Quiq::AsciiTable->new($table);
    $self->is(ref($tab),'Quiq::AsciiTable');

    my $width = $tab->width;
    $self->is($width,3);

    my $rangeA = $tab->rangeA;
    $self->isDeeply($rangeA,[
        [1,0,7],
        [0,7,1],
        [1,8,7],
        [0,15,1],
        [1,16,8],
    ]);

    my $multiLine = $tab->multiLine;
    $self->is($multiLine,0);

    my $titleA = $tab->titles;
    $self->isDeeply($titleA,[
        "Right\nAligned",
        "Left\nAligned",
        "Centered\nHeader"]);

    my $alignA = $tab->alignments;
    $self->isDeeply($alignA,['r','l','c']);

    my $rowA = $tab->rows;
    $self->is(scalar(@$rowA),3);
    $self->isDeeply($rowA,[
        ['1',  'A',  'A'],
        ['21', 'AB', 'AB'],
        ['321','ABC','ABC'],
    ]);
}

# -----------------------------------------------------------------------------

sub test_unitTest_MultiLineBody1 : Test(8) {
    my $self = shift;

    # Tabelle mit Titel und Zellenausrichtung

    my $table = q~
          Right   Left             
        Aligned   Aligned          Centered
        -------   --------------   --------
              1   This is             A
                  the first line

              2   Second line         B

              3   The third           C
                  line
    ~;

    my $tab = Quiq::AsciiTable->new($table);
    $self->is(ref($tab),'Quiq::AsciiTable');

    my $width = $tab->width;
    $self->is($width,3);

    my $rangeA = $tab->rangeA;
    $self->isDeeply($rangeA,[
        [1,0,7],
        [0,7,3],
        [1,10,14],
        [0,24,3],
        [1,27,8],
    ]);

    my $multiLine = $tab->multiLine;
    $self->ok($multiLine > 0);

    my $titleA = $tab->titles;
    $self->isDeeply($titleA,[
        "Right\nAligned",
        "Left\nAligned",
        "Centered"]);

    my $alignA = $tab->alignments;
    $self->isDeeply($alignA,['r','l','c']);

    my $rowA = $tab->rows;
    $self->is(scalar(@$rowA),3);
    $self->isDeeply($rowA,[
        ['1',"This is\nthe first line",'A'],
        ['2',"Second line",            'B'],
        ['3',"The third\nline",        'C'],
    ]);
}

# -----------------------------------------------------------------------------

sub test_unitTest_MultiLineBody2 : Test(8) {
    my $self = shift;

    # Tabelle mit Titel und Zellenausrichtung

    my $table = q~
          Right   Left             
        Aligned   Aligned          Centered
        -------   --------------   --------
              1   This is             A
                  the first line
        -------   --------------   --------
              2   Second line         B
        -------   --------------   --------
              3   The third           C
                  line
        -------   --------------   --------
    ~;

    my $tab = Quiq::AsciiTable->new($table);
    $self->is(ref($tab),'Quiq::AsciiTable');

    my $width = $tab->width;
    $self->is($width,3);

    my $rangeA = $tab->rangeA;
    $self->isDeeply($rangeA,[
        [1,0,7],
        [0,7,3],
        [1,10,14],
        [0,24,3],
        [1,27,8],
    ]);

    my $multiLine = $tab->multiLine;
    $self->ok($multiLine > 0);

    my $titleA = $tab->titles;
    $self->isDeeply($titleA,[
        "Right\nAligned",
        "Left\nAligned",
        "Centered"]);

    my $alignA = $tab->alignments;
    $self->isDeeply($alignA,['r','l','c']);

    my $rowA = $tab->rows;
    $self->is(scalar(@$rowA),3);
    $self->isDeeply($rowA,[
        ['1',"This is\nthe first line",'A'],
        ['2',"Second line",            'B'],
        ['3',"The third\nline",        'C'],
    ]);
}

# -----------------------------------------------------------------------------

package main;
Quiq::AsciiTable::Test->runTests;

# eof
