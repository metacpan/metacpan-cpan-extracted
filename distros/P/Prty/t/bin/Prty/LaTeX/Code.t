#!/usr/bin/env perl

package Prty::LaTeX::Code::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::LaTeX::Code');
}

# -----------------------------------------------------------------------------

sub test_protect : Test(1) {
    my $self = shift;

    my $l = Prty::LaTeX::Code->new;
    
    my $code = $l->protect('Der Text $text wird geschützt.');
    $self->is($code,'Der Text \$text wird geschützt.');
}

# -----------------------------------------------------------------------------

sub test_env : Test(1) {
    my $self = shift;

    my $l = Prty::LaTeX::Code->new;
    
    my $code = $l->env('document','Dies ist ein Text.');
    $self->is($code,Prty::Unindent->string(q~
        \begin{document}
        Dies ist ein Text.
        \end{document}
    ~));
}

# -----------------------------------------------------------------------------

sub test_section : Test(1) {
    my $self = shift;

    my $l = Prty::LaTeX::Code->new;

    my $code = $l->section('subsection','Titel');
    $self->is($code,"\\subsection{Titel}\n\n");
}

# -----------------------------------------------------------------------------

package main;
Prty::LaTeX::Code::Test->runTests;

# eof
