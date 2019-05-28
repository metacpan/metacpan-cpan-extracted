#!/usr/bin/env perl

package Quiq::Html::Widget::ReadOnly::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Widget::ReadOnly');
}

# -----------------------------------------------------------------------------

sub test_html : Test(3) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    # leer

    my $html = Quiq::Html::Widget::ReadOnly->html($h);
    $self->is($html,'');

    # ohne CSS

    $html = Quiq::Html::Widget::ReadOnly->html($h,
        name => 'x',
        value => 4711,
    );
    $self->is($html,qq|<input type="hidden" name="x" value="4711" />4711\n|);

    # mit CSS

    $html = Quiq::Html::Widget::ReadOnly->html($h,
        id => 'x1',
        name => 'x',
        value => 4711,
    );
    $self->is($html,q|<span id="x1"><input type="hidden" name="x"|.
        qq| value="4711" />4711</span>\n|);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Widget::ReadOnly::Test->runTests;

# eof
