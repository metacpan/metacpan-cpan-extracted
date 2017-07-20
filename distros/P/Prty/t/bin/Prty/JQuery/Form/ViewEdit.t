#!/usr/bin/env perl

package Prty::JQuery::Form::ViewEdit::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

use Prty::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::JQuery::Form::ViewEdit');
}

# -----------------------------------------------------------------------------

sub test_unitTest_1 : Test(2) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $e = Prty::JQuery::Form::ViewEdit->new(
        layout=>'__SAVE__ __DELETE__ __EDIT__',
    );
    $self->is(ref($e),'Prty::JQuery::Form::ViewEdit');

    my $html = $e->html($h);
    $self->ok($html);
}

# -----------------------------------------------------------------------------

package main;
Prty::JQuery::Form::ViewEdit::Test->runTests;

# eof
