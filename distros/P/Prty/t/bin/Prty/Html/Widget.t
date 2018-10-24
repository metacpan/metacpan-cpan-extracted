#!/usr/bin/env perl

package Prty::Html::Widget::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Widget');
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Widget::Test->runTests;

# eof
