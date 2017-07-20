#!/usr/bin/env perl

package Prty::Html::Widget::SelectMenu::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

use Prty::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Widget::SelectMenu');
}

# -----------------------------------------------------------------------------

sub test_html : Test(1) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $html = Prty::Html::Widget::SelectMenu->html($h);
    $self->is($html,'<select></select>');
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Widget::SelectMenu::Test->runTests;

# eof
