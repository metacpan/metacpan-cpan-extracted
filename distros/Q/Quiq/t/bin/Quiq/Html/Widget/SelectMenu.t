#!/usr/bin/env perl

package Quiq::Html::Widget::SelectMenu::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Widget::SelectMenu');
}

# -----------------------------------------------------------------------------

sub test_html : Test(1) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $html = Quiq::Html::Widget::SelectMenu->html($h);
    $self->is($html,'<select></select>');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Widget::SelectMenu::Test->runTests;

# eof
