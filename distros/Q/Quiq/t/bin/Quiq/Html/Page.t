#!/usr/bin/env perl

package Quiq::Html::Page::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Page');
}

# -----------------------------------------------------------------------------

sub test_html : Test(5) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $html = Quiq::Html::Page->html($h);
    $self->like($html,qr/DOCTYPE/,'html: DOCTYPE');
    $self->like($html,qr/html/,'html: html');
    $self->like($html,qr/head/,'html: head');
    $self->like($html,qr/charset/,'html: charset');
    $self->like($html,qr/body/,'html: body');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Page::Test->runTests;

# eof
