#!/usr/bin/env perl

package Quiq::Html::Widget::RadioButton::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Widget::RadioButton');
}

# -----------------------------------------------------------------------------

sub test_html : Test(2) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new('html5');

    my $html = Quiq::Html::Widget::RadioButton->html($h);
    $self->is($html,qq|<input type="radio">\n|);

    $html = Quiq::Html::Widget::RadioButton->html($h,
        name => 'aktiv',
        option => 1,
        value => '',
    );
    $self->is($html,qq|<input type="radio" name="aktiv" value="1">\n|);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Widget::RadioButton::Test->runTests;

# eof
