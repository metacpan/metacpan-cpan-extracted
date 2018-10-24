#!/usr/bin/env perl

package Prty::Html::Widget::CheckBox::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Prty::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Widget::CheckBox');
}

# -----------------------------------------------------------------------------

sub test_html : Test(2) {
    my $self = shift;

    my $h = Prty::Html::Tag->new('html5');

    my $html = Prty::Html::Widget::CheckBox->html($h);
    $self->is($html,qq|<input type="checkbox">\n|);

    $html = Prty::Html::Widget::CheckBox->html($h,
        name=>'aktiv',
        option=>1,
        value=>'',
    );
    $self->is($html,qq|<input type="checkbox" name="aktiv" value="1">\n|);
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Widget::CheckBox::Test->runTests;

# eof
