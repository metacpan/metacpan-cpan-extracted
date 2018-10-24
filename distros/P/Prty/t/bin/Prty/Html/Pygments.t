#!/usr/bin/env perl

package Prty::Html::Pygments::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Prty::Unindent;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Pygments');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(4) {
    my $self = shift;

    # CSS

    my ($rules,$bgColor) = Prty::Html::Pygments->css;
    $self->like($rules,qr/^\.[a-z]+/);
    $self->like($bgColor,qr/^#[0-9A-Fa-f]{6}/);

    # HTML

    my $html = Prty::Html::Pygments->html('perl',
        Prty::Unindent->trimNl(q~
            print "Hello, world!\n";
        ~),
    );
    $self->like($html,qr/Hello, world!/);

    # Styles durchtesten (es darf keine Exception geben, weil der
    # Style nicht bekannt ist oder die Hintergrundfarbe nicht
    # bestimmt werden kann)

    my $n = 0;
    for my $style (Prty::Html::Pygments->styles) {
        $n++;
        my ($rules,$bgColor) = Prty::Html::Pygments->css($style);
    }
    $self->ok($n);
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Pygments::Test->runTests;

# eof
