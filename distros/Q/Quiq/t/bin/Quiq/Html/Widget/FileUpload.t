#!/usr/bin/env perl

package Quiq::Html::Widget::FileUpload::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Widget::FileUpload');
}

# -----------------------------------------------------------------------------

sub test_html : Test(3) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $html = Quiq::Html::Widget::FileUpload->html($h);
    $self->is($html,qq|<input type="file" />\n|);

    $html = Quiq::Html::Widget::FileUpload->html($h,
        name=>'file1',
        size=>20,
    );
    $self->is($html,'<input type="file" name="file1" size="20"'.
        qq| maxlength="20" />\n|);

    $html = Quiq::Html::Widget::FileUpload->html($h,
        name=>'file1',
        size=>20,
        maxLength=>0,
    );
    $self->is($html,qq|<input type="file" name="file1" size="20" />\n|);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Widget::FileUpload::Test->runTests;

# eof
