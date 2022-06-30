#!/usr/bin/env perl

package Quiq::JQuery::MenuBar::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::JQuery::MenuBar');
}

# -----------------------------------------------------------------------------

package main;
Quiq::JQuery::MenuBar::Test->runTests;

# eof
