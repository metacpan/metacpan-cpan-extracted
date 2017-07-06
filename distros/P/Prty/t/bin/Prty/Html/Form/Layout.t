#!/usr/bin/env perl

package Prty::Html::Form::Layout::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Form::Layout');
}

# -----------------------------------------------------------------------------

sub test_unitTest_1 : Test(2) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $e = Prty::Html::Form::Layout->new;
    $self->is(ref($e),'Prty::Html::Form::Layout');

    my $html = $e->html($h);
    $self->is($html,'');
}

sub test_unitTest_2 : Test(1) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $expected = $h->tag('div',
        Prty::Html::Widget::TextField->html($h,
            name=>'vorname',
            value=>'Linus',
        ),
    );

    my $e = Prty::Html::Form::Layout->new(
        layout=>$h->tag('div',
            '__VORNAME__',
        ),
        widgets=>[
            Prty::Html::Widget::TextField->new(
                name=>'vorname',
                value=>'Linus',
            ),
        ],
    );

    my $html = $e->html($h);
    $self->is($html,$expected);
}

sub test_unitTest_3 : Test(1) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $e = Prty::Html::Form::Layout->new(
        layout=>$h->tag('div',
            '__NACHNAME__',
        ),
        widgets=>[
            Prty::Html::Widget::TextField->new(
                name=>'vorname',
                value=>'Linus',
            ),
        ],
    );

    eval {$e->html($h)};
    $self->ok($@);
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Form::Layout::Test->runTests;

# eof
