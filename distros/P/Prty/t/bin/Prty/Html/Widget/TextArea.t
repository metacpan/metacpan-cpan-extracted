#!/usr/bin/env perl

package Prty::Html::Widget::TextArea::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Widget::TextArea');
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Widget::TextArea::Test->runTests;

# eof
