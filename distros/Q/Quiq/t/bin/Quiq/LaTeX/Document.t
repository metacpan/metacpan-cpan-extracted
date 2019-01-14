#!/usr/bin/env perl

package Quiq::LaTeX::Document::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::LaTeX::Code;
use Quiq::Unindent;
use Quiq::LaTeX::Document;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::LaTeX::Document');
}

# -----------------------------------------------------------------------------

sub test_unitTest_0 : Test(2) {
    my $self = shift;

    my $l = Quiq::LaTeX::Code->new;
    my $doc = Quiq::LaTeX::Document->new;
    $self->is(ref($doc),'Quiq::LaTeX::Document');

    my $code = $doc->latex($l);
    $self->is($code,Quiq::Unindent->string(q~
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

    my $l = Quiq::LaTeX::Code->new;
    my $code = Quiq::LaTeX::Document->latex($l,
        body => 'Hallo Welt!',
    );
    $self->is($code,Quiq::Unindent->string(q~
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
Quiq::LaTeX::Document::Test->runTests;

# eof
