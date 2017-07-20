#!/usr/bin/env perl

package Prty::Html::Widget::Button::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

use Prty::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Widget::Button');
}

# -----------------------------------------------------------------------------

sub test_html : Test(2) {
    my $self = shift;

    my $h = Prty::Html::Tag->new('html5');

    my $html = Prty::Html::Widget::Button->html($h);
    $self->is($html,qq|<button type="button"></button>\n|);

    $html = Prty::Html::Widget::Button->html($h,
        name=>'aktion',
        value=>'Speichern',
    );
    $self->is($html,qq|<button name="aktion" type="button"|.
        qq| value="Speichern">Speichern</button>\n|);
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Widget::Button::Test->runTests;

# eof
