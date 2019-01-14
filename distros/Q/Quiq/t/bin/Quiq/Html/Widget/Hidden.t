#!/usr/bin/env perl

package Quiq::Html::Widget::Hidden::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Widget::Hidden');
}

# -----------------------------------------------------------------------------

sub test_html : Test(3) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    # leer

    my $html = Quiq::Html::Widget::Hidden->html($h);
    $self->is($html,'');

    # Wert

    $html = Quiq::Html::Widget::Hidden->html($h,
        name=>'x',
        value=>4711,
    );
    $self->is($html,qq|<input type="hidden" name="x" value="4711" />\n|);

    # Liste

    $html = Quiq::Html::Widget::Hidden->html($h,
        name=>'x',
        value=>[4711,4712],
    );
    $self->is($html,qq|<input type="hidden" name="x" value="4711" />\n|.
        qq|<input type="hidden" name="x" value="4712" />\n|);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Widget::Hidden::Test->runTests;

# eof
