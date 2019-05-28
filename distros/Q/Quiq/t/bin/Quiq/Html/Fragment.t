#!/usr/bin/env perl

package Quiq::Html::Fragment::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Fragment');
}

# -----------------------------------------------------------------------------

sub test_html_1 : Test(2) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $c = Quiq::Html::Fragment->new;
    $self->is(ref($c),'Quiq::Html::Fragment');

    my $html = $c->html($h);
    $self->is($html,'');
}

sub test_html_2 : Test(1) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $expected = $h->tag('div',
        'Ein Test',
    );

    my $c = Quiq::Html::Fragment->new(
        html => $h->tag('div',
            'Ein Test'
        ),
    );

    my $html = $c->html($h);
    $self->is($html,$expected);
}

sub test_html_3 : Test(1) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $expected = $h->cat(
        $h->tag('style',q|
            #container {
                background-color: red;
            }
        |),
        $h->tag('div',
            id => 'container',
            'Ein Test',
        ),
        $h->tag('script',q|
            $(function() {
                alert('ready');
            });
        |),
    );

    my $c = Quiq::Html::Fragment->new(
        styleSheet => q|
            #container {
                background-color: red;
            }
        |,
        html => $h->tag('div',
            id => 'container',
            '__TEXT__'
        ),
        javaScript => q|
            $(function() {
                alert('ready');
            });
        |,
        placeholders => [
            __TEXT__ => 'Ein Test',
        ],
    );

    my $html = $c->html($h);
    $self->is($html,$expected);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Fragment::Test->runTests;

# eof
