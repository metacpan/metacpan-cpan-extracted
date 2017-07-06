#!/usr/bin/env perl

package Prty::Html::Widget::Hidden::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Widget::Hidden');
}

# -----------------------------------------------------------------------------

sub test_html : Test(3) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    # leer

    my $html = Prty::Html::Widget::Hidden->html($h);
    $self->is($html,'');

    # Wert

    $html = Prty::Html::Widget::Hidden->html($h,
        name=>'x',
        value=>4711,
    );
    $self->is($html,qq|<input type="hidden" name="x" value="4711" />\n|);

    # Liste

    $html = Prty::Html::Widget::Hidden->html($h,
        name=>'x',
        value=>[4711,4712],
    );
    $self->is($html,qq|<input type="hidden" name="x" value="4711" />\n|.
        qq|<input type="hidden" name="x" value="4712" />\n|);
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Widget::Hidden::Test->runTests;

# eof
