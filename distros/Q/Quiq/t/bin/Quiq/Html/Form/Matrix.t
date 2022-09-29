#!/usr/bin/env perl

package Quiq::Html::Form::Matrix::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Html::Tag;
use Quiq::Html::Widget::TextField;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Form::Matrix');
}

# -----------------------------------------------------------------------------

sub test_unitTest_1 : Test(2) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $e = Quiq::Html::Form::Matrix->new;
    $self->is(ref($e),'Quiq::Html::Form::Matrix');

    my $html = $e->html($h);
    $self->is($html,'');
}

sub test_unitTest_2 : Test(0) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $e = Quiq::Html::Form::Matrix->new(
        titles => [qw/Konto/],
        rows => 3,
        widgets => [
            Quiq::Html::Widget::TextField->new(
                name => 'fbb_fibukonto',
                size => 4,
                maxLength => 4,
            ),
        ],
        initialize => sub {
            my ($w,$name,$i) = @_;

            my $val = "VAL$i";
            $w->value($val);
        },
    );

    my $html = $e->html($h);
    # warn "---\n$html---\n";
    # $self->is($html,'');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Form::Matrix::Test->runTests;

# eof
