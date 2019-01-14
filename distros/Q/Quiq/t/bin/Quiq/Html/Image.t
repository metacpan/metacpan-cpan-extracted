#!/usr/bin/env perl

package Quiq::Html::Image::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Html::Tag;
use Quiq::Unindent;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Image');
}

# -----------------------------------------------------------------------------

sub test_unitTest_empty : Test(2) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new('html5');

    my $e = Quiq::Html::Image->new;
    $self->is(ref($e),'Quiq::Html::Image');

    my $html = $e->html($h);
    $self->is($html,'');

    return;
}

sub test_unitTest_nonempty : Test(1) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new('html5');

    my $html = Quiq::Html::Image->html($h,
        src => 'img/illusion.png',
        width => 100,
        height => 100,
    );
    $self->is($html,Quiq::Unindent->trimNl(q~
        <div>
          <img src="img/illusion.png" width="100" height="100" alt="">
        </div>
    ~));
    
    return;
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Image::Test->runTests;

# eof
