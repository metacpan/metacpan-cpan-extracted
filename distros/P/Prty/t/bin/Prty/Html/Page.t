#!/usr/bin/env perl

package Prty::Html::Page::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Prty::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Page');
}

# -----------------------------------------------------------------------------

sub test_html : Test(5) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $html = Prty::Html::Page->html($h);
    $self->like($html,qr/DOCTYPE/,'html: DOCTYPE');
    $self->like($html,qr/html/,'html: html');
    $self->like($html,qr/head/,'html: head');
    $self->like($html,qr/charset/,'html: charset');
    $self->like($html,qr/body/,'html: body');
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Page::Test->runTests;

# eof
