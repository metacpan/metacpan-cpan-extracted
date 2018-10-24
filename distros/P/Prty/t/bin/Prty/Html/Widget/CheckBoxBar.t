#!/usr/bin/env perl

package Prty::Html::Widget::CheckBoxBar::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Prty::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Widget::CheckBoxBar');
}

# -----------------------------------------------------------------------------

sub test_html : Test(2) {
    my $self = shift;

    my $h = Prty::Html::Tag->new('html5');

    my $html = Prty::Html::Widget::CheckBoxBar->html($h);
    $self->is($html,'');

    my $expected =
        q|<input type="checkbox" name="farben" value="rot" checked>rot|.
        q| <input type="checkbox" name="farben" value="blau" checked>blau|.
        q| <input type="checkbox" name="farben" value="gelb">gelb|;

    $html = Prty::Html::Widget::CheckBoxBar->html($h,
        name=>'farben',
        options=>[qw/rot blau gelb/],
        values=>[qw/blau rot/],
    );
    $self->is($html,$expected);
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Widget::CheckBoxBar::Test->runTests;

# eof
