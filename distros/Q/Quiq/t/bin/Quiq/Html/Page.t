#!/usr/bin/env perl

package Quiq::Html::Page::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Html::Producer;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Page');
}

# -----------------------------------------------------------------------------

sub test_html : Test(5) {
    my $self = shift;

    my $h = Quiq::Html::Producer->new;

    my $html = Quiq::Html::Page->html($h);
    $self->like($html,qr/DOCTYPE/,'html: DOCTYPE');
    $self->like($html,qr/html/,'html: html');
    $self->like($html,qr/head/,'html: head');
    $self->like($html,qr/charset/,'html: charset');
    $self->like($html,qr/body/,'html: body');
}

sub test_html_2 : Test(2) {
    my $self = shift;

    my $expected = Quiq::Unindent->string(q~
    <!DOCTYPE html>

    <html>
    <head>
      <meta http-equiv="content-type" content="text/html; charset=utf-8" />
      <link rel="stylesheet" type="text/css" href="https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css" />
      <script type="text/javascript" src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js"></script>
    </head>
    <body></body>
    </html>
    ~);

    my $h = Quiq::Html::Producer->new;

    my $html = Quiq::Html::Page->html($h,
        load => [
            css =>
                'https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css',
            js => 'https://code.jquery.com/ui/1.12.1/jquery-ui.min.js',
        ],
    );
    $self->is($html,$expected);

    $html = Quiq::Html::Page->html($h,
        load => [
            'https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css',
            'https://code.jquery.com/ui/1.12.1/jquery-ui.min.js',
        ],
    );
    $self->is($html,$expected);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Page::Test->runTests;

# eof
