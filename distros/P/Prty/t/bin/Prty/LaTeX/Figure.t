#!/usr/bin/env perl

package Prty::LaTeX::Figure::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

use Prty::LaTeX::Code;
use Prty::Unindent;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::LaTeX::Figure');
}

# -----------------------------------------------------------------------------

sub test_unitTest_0 : Test(2) {
    my $self = shift;

    my $l = Prty::LaTeX::Code->new;
    my $fig = Prty::LaTeX::Figure->new;
    $self->is(ref($fig),'Prty::LaTeX::Figure');
    
    my $code = $fig->latex($l);
    $self->is($code,Prty::Unindent->string(q~
    ~));
}

# -----------------------------------------------------------------------------

package main;
Prty::LaTeX::Figure::Test->runTests;

# eof
