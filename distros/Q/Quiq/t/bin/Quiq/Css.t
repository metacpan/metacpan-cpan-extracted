#!/usr/bin/env perl

package Quiq::Css::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Css');
}

# -----------------------------------------------------------------------------

sub test_properties : Test(4) {
    my $self = shift;

    # Leer

    my $properties = Quiq::Css->properties;
    $self->is($properties,undef);

    # Als Klassenmethode

    $properties = Quiq::Css->properties(
        fontStyle => 'italic',
        marginLeft => '0.5cm',
        marginRight => '0.5cm',
    );
    $self->is($properties,
        'font-style: italic; margin-left: 0.5cm; margin-right: 0.5cm;');

    # Als Objektmethode mit Arrayreferenz

    $properties = Quiq::Css->new('flat')->properties([
        fontStyle => 'italic',
        marginLeft => '0.5cm',
        marginRight => '0.5cm',
    ]);
    $self->is($properties,
        'font-style: italic; margin-left: 0.5cm; margin-right: 0.5cm;');

    # Multiline

    $properties = Quiq::Css->new->properties(
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

    my $val = Quiq::Css->rule('p.abstract',
        fontStyle => 'italic',
        marginLeft => '0.5cm',
        marginRight => '0.5cm',
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

    my $css = Quiq::Css->new('flat');

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

    my $css = Quiq::Css->new('flat');

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

    my $expect = Quiq::Unindent->trimNl(q~
        p.comment { color: #408080; font-style: italic; }
        p.abstract { font-style: italic; margin-left: 1cm; }
    ~);
    $self->is($rules,$expect);
}

# -----------------------------------------------------------------------------

sub test_restrictedRules : Test(1) {
    my $self = shift;

    my $css = Quiq::Css->new('flat');

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

    my $expect = Quiq::Unindent->trimNl(q~
        #xxx p.comment { color: #408080; font-style: italic; }
        #xxx p.abstract { font-style: italic; margin-left: 1cm; }
    ~);
    $self->is($rules,$expect);
}

# -----------------------------------------------------------------------------

sub test_rulesFromObject : Test(1) {
    my $self = shift;

    my $css = Quiq::Css->new('flat');

    my $obj = Quiq::Hash->new(
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

    my $expected = Quiq::Unindent->trimNl(q~
        .xxx-table { background-color: #f0f0f0; }
        .xxx-ln { color: black; }
        .xxx-margin { width: 0.6em; background-color: red; }
    ~);
    $self->is($rules,$expected);
}

# -----------------------------------------------------------------------------

sub test_makeFlat : Test(1) {
    my $self = shift;

    my $rules = Quiq::Css->makeFlat(Quiq::Unindent->trimNl(q~
        .sdoc-document h1 {
        font-size: 230%;
        margin-bottom: 10px;
        }
        .sdoc-document p {
        margin-top: 10px;
        }
    ~));
    $self->is($rules,Quiq::Unindent->trimNl(q~
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

    my $h = Quiq::Html::Tag->new;

    # ---
        
    my $val = Quiq::Css->style($h);
    $self->is($val,'');

    # ---

    $val = Quiq::Css->style($h,$spec1);
    $self->is($val,$style1);

    # ---

    $val = Quiq::Css->style($h,$spec2);
    $self->is($val,$style2);

    # ---

    $val = Quiq::Css->style($h,$spec1,$spec2);
    $self->is($val,"$style1$style2");

    # ---

    $val = Quiq::Css->style($h,[$spec1,$spec2]);
    $self->is($val,"$style1$style2");
}

# -----------------------------------------------------------------------------

package main;
Quiq::Css::Test->runTests;

# eof
