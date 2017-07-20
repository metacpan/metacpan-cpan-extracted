#!/usr/bin/env perl

package Prty::Html::Widget::TextField::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

use Prty::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Widget::TextField');
}

# -----------------------------------------------------------------------------

sub test_html : Test(3) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $html = Prty::Html::Widget::TextField->html($h);
    $self->is($html,qq|<input type="text" />\n|);

    $html = Prty::Html::Widget::TextField->html($h,
        name=>'text1',
        size=>20,
        value=>'ein Text',
    );
    $self->is($html,'<input type="text" name="text1" size="20" maxlength="20"'.
        qq| value="ein Text" />\n|);

    $html = Prty::Html::Widget::TextField->html($h,
        name=>'text1',
        size=>20,
        maxLength=>0,
        value=>'ein Text',
    );
    $self->is($html,qq|<input type="text" name="text1" size="20"|.
        qq| value="ein Text" />\n|);
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Widget::TextField::Test->runTests;

# eof
