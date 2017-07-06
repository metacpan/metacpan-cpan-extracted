#!/usr/bin/env perl

package Prty::Html::Widget::FileUpload::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Widget::FileUpload');
}

# -----------------------------------------------------------------------------

sub test_html : Test(3) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $html = Prty::Html::Widget::FileUpload->html($h);
    $self->is($html,qq|<input type="file" />\n|);

    $html = Prty::Html::Widget::FileUpload->html($h,
        name=>'file1',
        size=>20,
    );
    $self->is($html,'<input type="file" name="file1" size="20"'.
        qq| maxlength="20" />\n|);

    $html = Prty::Html::Widget::FileUpload->html($h,
        name=>'file1',
        size=>20,
        maxLength=>0,
    );
    $self->is($html,qq|<input type="file" name="file1" size="20" />\n|);
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Widget::FileUpload::Test->runTests;

# eof
