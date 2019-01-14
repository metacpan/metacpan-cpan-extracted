#!/usr/bin/env perl

package Quiq::Html::Widget::Button::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Widget::Button');
}

# -----------------------------------------------------------------------------

sub test_html : Test(2) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new('html5');

    my $html = Quiq::Html::Widget::Button->html($h);
    $self->is($html,qq|<button type="button"></button>\n|);

    $html = Quiq::Html::Widget::Button->html($h,
        name=>'aktion',
        value=>'Speichern',
    );
    $self->is($html,qq|<button name="aktion" type="button"|.
        qq| value="Speichern">Speichern</button>\n|);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Widget::Button::Test->runTests;

# eof
