#!/usr/bin/env perl

package Quiq::Html::Form::Layout::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Html::Tag;
use Quiq::Html::Widget::TextField;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Form::Layout');
}

# -----------------------------------------------------------------------------

sub test_unitTest_1 : Test(2) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $e = Quiq::Html::Form::Layout->new;
    $self->is(ref($e),'Quiq::Html::Form::Layout');

    my $html = $e->html($h);
    $self->is($html,'');
}

sub test_unitTest_2 : Test(1) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $expected = $h->tag('div',
        Quiq::Html::Widget::TextField->html($h,
            name=>'vorname',
            value=>'Linus',
        ),
    );

    my $e = Quiq::Html::Form::Layout->new(
        layout=>$h->tag('div',
            '__VORNAME__',
        ),
        widgets=>[
            Quiq::Html::Widget::TextField->new(
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

    my $h = Quiq::Html::Tag->new;

    my $e = Quiq::Html::Form::Layout->new(
        layout=>$h->tag('div',
            '__NACHNAME__',
        ),
        widgets=>[
            Quiq::Html::Widget::TextField->new(
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
Quiq::Html::Form::Layout::Test->runTests;

# eof
