#!/usr/bin/env perl

package Quiq::JQuery::Form::ViewEdit::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::JQuery::Form::ViewEdit');
}

# -----------------------------------------------------------------------------

sub test_unitTest_1 : Test(2) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $e = Quiq::JQuery::Form::ViewEdit->new(
        layout => '__SAVE__ __DELETE__ __EDIT__',
    );
    $self->is(ref($e),'Quiq::JQuery::Form::ViewEdit');

    my $html = $e->html($h);
    $self->ok($html);
}

# -----------------------------------------------------------------------------

package main;
Quiq::JQuery::Form::ViewEdit::Test->runTests;

# eof
