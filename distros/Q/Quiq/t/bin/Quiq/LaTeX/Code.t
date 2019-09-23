#!/usr/bin/env perl

package Quiq::LaTeX::Code::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::LaTeX::Code');
}

# -----------------------------------------------------------------------------

sub test_protect : Test(1) {
    my $self = shift;

    my $l = Quiq::LaTeX::Code->new;
    
    my $code = $l->protect('Der Text $text wird geschützt.');
    $self->is($code,'Der Text \$text wird geschützt.');
}

# -----------------------------------------------------------------------------

sub test_env : Test(1) {
    my $self = shift;

    my $l = Quiq::LaTeX::Code->new;
    
    my $code = $l->env('document','Dies ist ein Text.');
    $self->is($code,Quiq::Unindent->string(q~
        \begin{document}
        Dies ist ein Text.
        \end{document}
    ~));
}

# -----------------------------------------------------------------------------

sub test_section : Test(1) {
    my $self = shift;

    my $l = Quiq::LaTeX::Code->new;

    my $code = $l->section('subsection','Titel');
    $self->is($code,"\\subsection{Titel}\n\n");
}

# -----------------------------------------------------------------------------

package main;
Quiq::LaTeX::Code::Test->runTests;

# eof
