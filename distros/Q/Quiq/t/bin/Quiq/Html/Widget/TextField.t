#!/usr/bin/env perl

package Quiq::Html::Widget::TextField::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Widget::TextField');
}

# -----------------------------------------------------------------------------

sub test_html : Test(3) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $html = Quiq::Html::Widget::TextField->html($h);
    $self->is($html,qq|<input type="text" />\n|);

    $html = Quiq::Html::Widget::TextField->html($h,
        name => 'text1',
        size => 20,
        value => 'ein Text',
    );
    $self->is($html,'<input type="text" name="text1" size="20" maxlength="20"'.
        qq| value="ein Text" />\n|);

    $html = Quiq::Html::Widget::TextField->html($h,
        name => 'text1',
        size => 20,
        maxLength => 0,
        value => 'ein Text',
    );
    $self->is($html,qq|<input type="text" name="text1" size="20"|.
        qq| value="ein Text" />\n|);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Widget::TextField::Test->runTests;

# eof
