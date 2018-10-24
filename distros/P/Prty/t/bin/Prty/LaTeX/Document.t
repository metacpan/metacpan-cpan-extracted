#!/usr/bin/env perl

package Prty::LaTeX::Document::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Prty::LaTeX::Code;
use Prty::Unindent;
use Prty::LaTeX::Document;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::LaTeX::Document');
}

# -----------------------------------------------------------------------------

sub test_unitTest_0 : Test(2) {
    my $self = shift;

    my $l = Prty::LaTeX::Code->new;
    my $doc = Prty::LaTeX::Document->new;
    $self->is(ref($doc),'Prty::LaTeX::Document');

    my $code = $doc->latex($l);
    $self->is($code,Prty::Unindent->string(q~
        \documentclass[ngerman,a4paper]{scrartcl}
        \usepackage[T1]{fontenc}
        \usepackage{lmodern}
        \usepackage[utf8]{inputenc}
        \usepackage{babel}
        \usepackage{geometry}
        \usepackage{microtype}
        \geometry{height=22.5cm,bottom=3.8cm}
        \setlength{\parindent}{0em}
        \setlength{\parskip}{0.5ex}
        \begin{document}
        \end{document}
    ~));
}

# -----------------------------------------------------------------------------

sub test_unitTest_1 : Test(1) {
    my $self = shift;

    my $l = Prty::LaTeX::Code->new;
    my $code = Prty::LaTeX::Document->latex($l,
        body => 'Hallo Welt!',
    );
    $self->is($code,Prty::Unindent->string(q~
        \documentclass[ngerman,a4paper]{scrartcl}
        \usepackage[T1]{fontenc}
        \usepackage{lmodern}
        \usepackage[utf8]{inputenc}
        \usepackage{babel}
        \usepackage{geometry}
        \usepackage{microtype}
        \geometry{height=22.5cm,bottom=3.8cm}
        \setlength{\parindent}{0em}
        \setlength{\parskip}{0.5ex}
        \begin{document}
        Hallo Welt!
        \end{document}
    ~));
}

# -----------------------------------------------------------------------------

package main;
Prty::LaTeX::Document::Test->runTests;

# eof
