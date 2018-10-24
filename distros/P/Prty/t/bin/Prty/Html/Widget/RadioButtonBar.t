#!/usr/bin/env perl

package Prty::Html::Widget::RadioButtonBar::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Prty::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Widget::RadioButtonBar');
}

# -----------------------------------------------------------------------------

sub test_html : Test(2) {
    my $self = shift;

    my $h = Prty::Html::Tag->new('html5');

    my $html = Prty::Html::Widget::RadioButtonBar->html($h);
    $self->is($html,'');

    my $expected =
        q|<input type="radio" name="vererbung" value="1" checked>erben|.
        q| <input type="radio" name="vererbung" value="0">lokal|;

    $html = Prty::Html::Widget::RadioButtonBar->html($h,
        name=>'vererbung',
        options=>[1,0],
        labels=>['erben','lokal'],
        value=>1,
    );
    $self->is($html,$expected);
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Widget::RadioButtonBar::Test->runTests;

# eof
