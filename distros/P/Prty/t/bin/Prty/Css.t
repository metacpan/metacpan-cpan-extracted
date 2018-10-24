#!/usr/bin/env perl

package Prty::Css::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Prty::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Css');
}

# -----------------------------------------------------------------------------

sub test_properties : Test(4) {
    my $self = shift;

    # Leer

    my $properties = Prty::Css->properties;
    $self->is($properties,undef);

    # Als Klassenmethode

    $properties = Prty::Css->properties(
        fontStyle => 'italic',
        marginLeft => '0.5cm',
        marginRight => '0.5cm',
    );
    $self->is($properties,
        'font-style: italic; margin-left: 0.5cm; margin-right: 0.5cm;');

    # Als Objektmethode mit Arrayreferenz

    $properties = Prty::Css->new('flat')->properties([
        fontStyle => 'italic',
        marginLeft => '0.5cm',
        marginRight => '0.5cm',
    ]);
    $self->is($properties,
        'font-style: italic; margin-left: 0.5cm; margin-right: 0.5cm;');

    # Multiline

    $properties = Prty::Css->new->properties(
        fontStyle => 'italic',
        marginLeft => '0.5cm',
        marginRight => '0.5cm',
    );
    $self->is($properties,
        "font-style: italic;\nmargin-left: 0.5cm;\nmargin-right: 0.5cm;");
}

# -----------------------------------------------------------------------------

sub test_rule_normal : Test(1) {
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

sub test_rule_flat : Test(1) {
    my $self = shift;

    my $css = Prty::Css->new('flat');

    my $val = $css->rule('.comment',
        color => '#408080',
        fontStyle => 'italic',
    );

    my $expect = ".comment { color: #408080; font-style: italic; }\n";
    $self->is($val,$expect);
}

# -----------------------------------------------------------------------------

sub test_rules : Test(1) {
    my $self = shift;

    my $css = Prty::Css->new('flat');

    my $rules = $css->rules(
        'p.comment' => [
            color => '#408080',
            fontStyle => 'italic',
        ],
        'p.abstract' => [
            fontStyle => 'italic',
            marginLeft => '1cm',
        ],
    );

    my $expect = Prty::Unindent->trimNl(q~
        p.comment { color: #408080; font-style: italic; }
        p.abstract { font-style: italic; margin-left: 1cm; }
    ~);
    $self->is($rules,$expect);
}

# -----------------------------------------------------------------------------

sub test_restrictedRules : Test(1) {
    my $self = shift;

    my $css = Prty::Css->new('flat');

    my $rules = $css->restrictedRules('#xxx',
        'p.comment' => [
            color => '#408080',
            fontStyle => 'italic',
        ],
        'p.abstract' => [
            fontStyle => 'italic',
            marginLeft => '1cm',
        ],
    );

    my $expect = Prty::Unindent->trimNl(q~
        #xxx p.comment { color: #408080; font-style: italic; }
        #xxx p.abstract { font-style: italic; margin-left: 1cm; }
    ~);
    $self->is($rules,$expect);
}

# -----------------------------------------------------------------------------

sub test_rulesFromObject : Test(1) {
    my $self = shift;

    my $css = Prty::Css->new('flat');

    my $obj = Prty::Hash->new(
        cssTableProperties => [backgroundColor=>'#f0f0f0'],
        cssLnProperties => [color=>'black'],
        cssMarginProperties => ['+',backgroundColor=>'red'],
        cssTextProperties => [],
    );

    my $prefix = 'xxx';
    my $rules .= $css->rulesFromObject($obj,
        cssTableProperties => [".$prefix-table"],
        cssLnProperties => [".$prefix-ln",color=>'#808080'],
        cssMarginProperties => [".$prefix-margin",width=>'0.6em'],
        cssTextProperties => [".$prefix-text"],
    );

    my $expected = Prty::Unindent->trimNl(q~
        .xxx-table { background-color: #f0f0f0; }
        .xxx-ln { color: black; }
        .xxx-margin { width: 0.6em; background-color: red; }
    ~);
    $self->is($rules,$expected);
}

# -----------------------------------------------------------------------------

sub test_makeFlat : Test(1) {
    my $self = shift;

    my $rules = Prty::Css->makeFlat(Prty::Unindent->trimNl(q~
        .sdoc-document h1 {
        font-size: 230%;
        margin-bottom: 10px;
        }
        .sdoc-document p {
        margin-top: 10px;
        }
    ~));
    $self->is($rules,Prty::Unindent->trimNl(q~
        .sdoc-document h1 { font-size: 230%; margin-bottom: 10px; }
        .sdoc-document p { margin-top: 10px; }
    ~));
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
