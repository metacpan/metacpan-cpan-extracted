#!/usr/bin/env perl

package Prty::Css::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Css');
}

# -----------------------------------------------------------------------------

sub test_rule : Test(1) {
    my $self = shift;

    my $val = Prty::Css->rule('p.abstract',
        fontStyle=>'italic',
        marginLeft=>'0.5cm',
        marginRight=>'0.5cm',
    );

    my $expect = << '    __CSS__';
    p.abstract {
        font-style: italic;
        margin-left: 0.5cm;
        margin-right: 0.5cm;
    }
    __CSS__
    $expect =~ s/^    //gm;

    $self->is($val,$expect);
}

# -----------------------------------------------------------------------------

sub test_style : Test(5) {
    my $self = shift;

    my $spec1 = '/css/style.css';
    my $style1 = qq|<link rel="stylesheet" type="text/css"|.
        qq| href="/css/style.css" />\n|;

    my $spec2 = 'a:hover { background: #0000ff; }';
    my $style2 = qq|<style type="text/css">\n  a:hover|.
        qq| { background: #0000ff; }\n</style>\n|;

    my $h = Prty::Html::Tag->new;

    # ---
        
    my $val = Prty::Css->style($h);
    $self->is($val,'');

    # ---

    $val = Prty::Css->style($h,$spec1);
    $self->is($val,$style1);

    # ---

    $val = Prty::Css->style($h,$spec2);
    $self->is($val,$style2);

    # ---

    $val = Prty::Css->style($h,$spec1,$spec2);
    $self->is($val,"$style1$style2");

    # ---

    $val = Prty::Css->style($h,[$spec1,$spec2]);
    $self->is($val,"$style1$style2");
}

# -----------------------------------------------------------------------------

package main;
Prty::Css::Test->runTests;

# eof
