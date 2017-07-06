#!/usr/bin/env perl

package Prty::Html::Widget::RadioButton::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Widget::RadioButton');
}

# -----------------------------------------------------------------------------

sub test_html : Test(2) {
    my $self = shift;

    my $h = Prty::Html::Tag->new('html5');

    my $html = Prty::Html::Widget::RadioButton->html($h);
    $self->is($html,qq|<input type="radio">\n|);

    $html = Prty::Html::Widget::RadioButton->html($h,
        name=>'aktiv',
        option=>1,
        value=>'',
    );
    $self->is($html,qq|<input type="radio" name="aktiv" value="1">\n|);
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Widget::RadioButton::Test->runTests;

# eof
