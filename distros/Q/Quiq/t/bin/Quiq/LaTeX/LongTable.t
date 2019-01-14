#!/usr/bin/env perl

package Quiq::LaTeX::LongTable::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

use Quiq::LaTeX::Code;
use Quiq::Unindent;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::LaTeX::LongTable');
}

# -----------------------------------------------------------------------------

sub test_unitTest_0 : Test(2) {
    my $self = shift;

    my $tab = Quiq::LaTeX::LongTable->new;
    $self->is(ref($tab),'Quiq::LaTeX::LongTable');

    my $l = Quiq::LaTeX::Code->new;
    my $code = $tab->latex($l);
    $self->is($code,'');
}

# -----------------------------------------------------------------------------

sub test_unitTest_1 : Test(1) {
    my $self = shift;

    my $tab = Quiq::LaTeX::LongTable->new(
        alignments => ['l','r','c'],
        caption => 'Ein Test',
        titles => ['Links','Rechts','Zentriert'],
        rows => [
            ['A',1,'AB'],
            ['AB',2,'CD'],
            ['ABC',3,'EF'],
            ['ABCD',4,'GH'],
        ],            
    );

    my $l = Quiq::LaTeX::Code->new;
    my $code = $tab->latex($l);
    $self->is($code,Quiq::Unindent->string(q~
        \begin{longtable}[c]{|lrc|}
        \hline
        Links & Rechts & Zentriert \\\\ \hline
        \endfirsthead
        \multicolumn{3}{r}{\emph{Fortsetzung}} \\\\
        \hline
        Links & Rechts & Zentriert \\\\ \hline
        \endhead
        \hline
        \multicolumn{3}{r}{\emph{weiter nächste Seite}} \\\\
        \endfoot
        \caption{Ein Test}
        \endlastfoot
        A & 1 & AB \\\\ \hline
        AB & 2 & CD \\\\ \hline
        ABC & 3 & EF \\\\ \hline
        ABCD & 4 & GH \\\\ \hline
        \end{longtable}
    ~));
}

# -----------------------------------------------------------------------------

package main;
Quiq::LaTeX::LongTable::Test->runTests;

# eof
