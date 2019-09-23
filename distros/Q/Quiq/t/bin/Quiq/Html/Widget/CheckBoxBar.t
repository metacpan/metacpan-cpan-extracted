#!/usr/bin/env perl

package Quiq::Html::Widget::CheckBoxBar::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Widget::CheckBoxBar');
}

# -----------------------------------------------------------------------------

sub test_html : Test(2) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new('html5');

    my $html = Quiq::Html::Widget::CheckBoxBar->html($h);
    $self->is($html,'');

    my $expected =
        q|<input type="checkbox" name="farben" value="rot" checked>rot|.
        q| <input type="checkbox" name="farben" value="blau" checked>blau|.
        q| <input type="checkbox" name="farben" value="gelb">gelb|;

    $html = Quiq::Html::Widget::CheckBoxBar->html($h,
        name => 'farben',
        options => [qw/rot blau gelb/],
        values => [qw/blau rot/],
    );
    $self->is($html,$expected);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Widget::CheckBoxBar::Test->runTests;

# eof
