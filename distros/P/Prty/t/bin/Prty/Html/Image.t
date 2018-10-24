#!/usr/bin/env perl

package Prty::Html::Image::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Prty::Html::Tag;
use Prty::Unindent;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Image');
}

# -----------------------------------------------------------------------------

sub test_unitTest_empty : Test(2) {
    my $self = shift;

    my $h = Prty::Html::Tag->new('html5');

    my $e = Prty::Html::Image->new;
    $self->is(ref($e),'Prty::Html::Image');

    my $html = $e->html($h);
    $self->is($html,'');

    return;
}

sub test_unitTest_nonempty : Test(1) {
    my $self = shift;

    my $h = Prty::Html::Tag->new('html5');

    my $html = Prty::Html::Image->html($h,
        src => 'img/illusion.png',
        width => 100,
        height => 100,
    );
    $self->is($html,Prty::Unindent->trimNl(q~
        <div>
          <img src="img/illusion.png" width="100" height="100" alt="">
        </div>
    ~));
    
    return;
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Image::Test->runTests;

# eof
