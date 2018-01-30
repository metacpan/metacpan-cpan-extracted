#!/usr/bin/env perl

package Prty::LaTeX::Generator::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::LaTeX::Generator');
}

# -----------------------------------------------------------------------------

sub test_cmd : Test(6) {
    my $self = shift;

    my $ltx = Prty::LaTeX::Generator->new;
    
    my $code = $ltx->cmd('LaTeX',-nl=>0);
    $self->is($code,"\\LaTeX");

    $code = $ltx->cmd('LaTeX',-p=>'',-nl=>0);
    $self->is($code,"\\LaTeX{}");

    $code = $ltx->cmd('documentclass',
        -p => 'article',
    );
    $self->is($code,"\\documentclass{article}\n");

    $code = $ltx->cmd('documentclass',
        -o => '12pt',
        -p => 'article',
    );
    $self->is($code,"\\documentclass[12pt]{article}\n");

    $code = $ltx->cmd('documentclass',
        -o => 'a4wide,12pt',
        -p => 'article',
    );
    $self->is($code,"\\documentclass[a4wide,12pt]{article}\n");

    $code = $ltx->cmd('documentclass',
        -o => ['a4wide','12pt'],
        -p => 'article',
    );
    $self->is($code,"\\documentclass[a4wide,12pt]{article}\n");
}

# -----------------------------------------------------------------------------

sub test_env : Test(1) {
    my $self = shift;

    my $ltx = Prty::LaTeX::Generator->new;
    
    my $code = $ltx->env('document','Dies ist ein Text.');
    $self->is($code,Prty::Unindent->string(q~
        \begin{document}
        Dies ist ein Text.
        \end{document}
    ~));
}

# -----------------------------------------------------------------------------

sub test_len : Test(1) {
    my $self = shift;

    my $ltx = Prty::LaTeX::Generator->new;
    
    my $code = $ltx->len('parindent','0em');
    $self->is($code,"\\parindent0em\n");
}

# -----------------------------------------------------------------------------

sub test_comment : Test(1) {
    my $self = shift;

    my $ltx = Prty::LaTeX::Generator->new;
    
    my $code = $ltx->comment("Dies ist\nein Kommentar");
    $self->is($code,"% Dies ist\n% ein Kommentar\n");
}

# -----------------------------------------------------------------------------

sub test_protect : Test(1) {
    my $self = shift;

    my $ltx = Prty::LaTeX::Generator->new;
    
    my $code = $ltx->protect('Der Text $text wird geschützt.');
    $self->is($code,'Der Text \$text wird geschützt.');
}

# -----------------------------------------------------------------------------

sub test_section : Test(1) {
    my $self = shift;

    my $ltx = Prty::LaTeX::Generator->new;

    my $code = $ltx->section('subsection','Titel');
    $self->is($code,"\\subsection{Titel}\n\n");
}

# -----------------------------------------------------------------------------

package main;
Prty::LaTeX::Generator::Test->runTests;

# eof
