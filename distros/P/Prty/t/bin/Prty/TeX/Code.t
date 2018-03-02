#!/usr/bin/env perl

package Prty::TeX::Code::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::TeX::Code');
}

# -----------------------------------------------------------------------------

sub test_c : Test(3) {
    my $self = shift;

    my $t = Prty::TeX::Code->new;
    
    my $code = $t->c('\documentclass[%s]{%s}','12pt','article');
    $self->is($code,'\documentclass[12pt]{article}'."\n");

    $code = $t->c('\usepackage[utf8]{inputenc}',-nl=>2);
    $self->is($code,'\usepackage[utf8]{inputenc}'."\n\n");

    my @opt;
    push @opt,'labelsep=colon';
    push @opt,'labelfont=bf';
    push @opt,'skip=1.5ex';
    $code = $t->c('\usepackage[%s]{caption}',\@opt);
    $self->is($code,
        "\\usepackage[labelsep=colon,labelfont=bf,skip=1.5ex]{caption}\n");
}

# -----------------------------------------------------------------------------

sub test_ci : Test(1) {
    my $self = shift;

    my $t = Prty::TeX::Code->new;
    
    my $code = $t->ci('\thead[%sb]{%s}','c','Ein Text');
    $self->is($code,'\thead[cb]{Ein Text}');
}

# -----------------------------------------------------------------------------

sub test_macro : Test(6) {
    my $self = shift;

    my $t = Prty::TeX::Code->new;
    
    my $code = $t->macro('\LaTeX',-nl=>0);
    $self->is($code,"\\LaTeX");

    $code = $t->macro('\LaTeX',-p=>'',-nl=>0);
    $self->is($code,"\\LaTeX{}");

    $code = $t->macro('\documentclass',
        -p => 'article',
    );
    $self->is($code,"\\documentclass{article}\n");

    $code = $t->macro('\documentclass',
        -o => '12pt',
        -p => 'article',
    );
    $self->is($code,"\\documentclass[12pt]{article}\n");

    $code = $t->macro('\documentclass',
        -o => 'a4wide,12pt',
        -p => 'article',
    );
    $self->is($code,"\\documentclass[a4wide,12pt]{article}\n");

    $code = $t->macro('\documentclass',
        -o => ['a4wide','12pt'],
        -p => 'article',
    );
    $self->is($code,"\\documentclass[a4wide,12pt]{article}\n");
}

# -----------------------------------------------------------------------------

sub test_comment : Test(1) {
    my $self = shift;

    my $l = Prty::TeX::Code->new;
    
    my $code = $l->comment("Dies ist\nein Kommentar");
    $self->is($code,"% Dies ist\n% ein Kommentar\n");
}

# -----------------------------------------------------------------------------

sub test_modifyLength : Test(1) {
    my $self = shift;

    my $l = Prty::TeX::Code->new;

    my $val = $l->modifyLength('1.5ex','*1.5');
    $self->is($val,'2.25ex');
}

# -----------------------------------------------------------------------------

package main;
Prty::TeX::Code::Test->runTests;

# eof
