#!/usr/bin/env perl

package Quiq::Html::Widget::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Widget');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Widget::Test->runTests;

# eof
