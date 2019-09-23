#!/usr/bin/env perl

package Quiq::Html::Widget::CheckBox::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Widget::CheckBox');
}

# -----------------------------------------------------------------------------

sub test_html : Test(2) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new('html5');

    my $html = Quiq::Html::Widget::CheckBox->html($h);
    $self->is($html,qq|<input type="checkbox">\n|);

    $html = Quiq::Html::Widget::CheckBox->html($h,
        name => 'aktiv',
        option => 1,
        value => '',
    );
    $self->is($html,qq|<input type="checkbox" name="aktiv" value="1">\n|);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Widget::CheckBox::Test->runTests;

# eof
