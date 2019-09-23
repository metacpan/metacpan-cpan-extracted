#!/usr/bin/env perl

package Quiq::Html::Widget::TextArea::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Widget::TextArea');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Widget::TextArea::Test->runTests;

# eof
