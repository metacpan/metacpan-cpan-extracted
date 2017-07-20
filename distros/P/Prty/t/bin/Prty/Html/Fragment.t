#!/usr/bin/env perl

package Prty::Html::Fragment::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

use Prty::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Fragment');
}

# -----------------------------------------------------------------------------

sub test_html_1 : Test(2) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $c = Prty::Html::Fragment->new;
    $self->is(ref($c),'Prty::Html::Fragment');

    my $html = $c->html($h);
    $self->is($html,'');
}

sub test_html_2 : Test(1) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $expected = $h->tag('div',
        'Ein Test',
    );

    my $c = Prty::Html::Fragment->new(
        html=>$h->tag('div',
            'Ein Test'
        ),
    );

    my $html = $c->html($h);
    $self->is($html,$expected);
}

sub test_html_3 : Test(1) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $expected = $h->cat(
        $h->tag('style',q|
            #container {
                background-color: red;
            }
        |),
        $h->tag('div',
            id=>'container',
            'Ein Test',
        ),
        $h->tag('script',q|
            $(function() {
                alert('ready');
            });
        |),
    );

    my $c = Prty::Html::Fragment->new(
        styleSheet=>q|
            #container {
                background-color: red;
            }
        |,
        html=>$h->tag('div',
            id=>'container',
            '__TEXT__'
        ),
        javaScript=>q|
            $(function() {
                alert('ready');
            });
        |,
        placeholders=>[
            __TEXT__=>'Ein Test',
        ],
    );

    my $html = $c->html($h);
    $self->is($html,$expected);
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Fragment::Test->runTests;

# eof
