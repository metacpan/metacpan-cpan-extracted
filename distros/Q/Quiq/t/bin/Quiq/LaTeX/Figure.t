#!/usr/bin/env perl

package Quiq::LaTeX::Figure::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::LaTeX::Code;
use Quiq::Unindent;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::LaTeX::Figure');
}

# -----------------------------------------------------------------------------

sub test_unitTest_0 : Test(2) {
    my $self = shift;

    my $l = Quiq::LaTeX::Code->new;
    my $fig = Quiq::LaTeX::Figure->new;
    $self->is(ref($fig),'Quiq::LaTeX::Figure');
    
    my $code = $fig->latex($l);
    $self->is($code,Quiq::Unindent->string(q~
    ~));
}

# -----------------------------------------------------------------------------

package main;
Quiq::LaTeX::Figure::Test->runTests;

# eof
