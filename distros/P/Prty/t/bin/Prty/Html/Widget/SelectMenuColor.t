#!/usr/bin/env perl

package Prty::Html::Widget::SelectMenuColor::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Widget::SelectMenuColor');
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Widget::SelectMenuColor::Test->runTests;

# eof
