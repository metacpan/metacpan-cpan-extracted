#!/usr/bin/env perl

package Quiq::Html::Widget::RadioButtonBar::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Widget::RadioButtonBar');
}

# -----------------------------------------------------------------------------

sub test_html : Test(2) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new('html5');

    my $html = Quiq::Html::Widget::RadioButtonBar->html($h);
    $self->is($html,'');

    my $expected =
        q|<input type="radio" name="vererbung" value="1" checked>erben|.
        q| <input type="radio" name="vererbung" value="0">lokal|;

    $html = Quiq::Html::Widget::RadioButtonBar->html($h,
        name=>'vererbung',
        options=>[1,0],
        labels=>['erben','lokal'],
        value=>1,
    );
    $self->is($html,$expected);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Widget::RadioButtonBar::Test->runTests;

# eof
