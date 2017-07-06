#!/usr/bin/env perl

package Prty::Html::Widget::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Widget');
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Widget::Test->runTests;

# eof
