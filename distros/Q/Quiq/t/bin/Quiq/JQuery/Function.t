#!/usr/bin/env perl

package Quiq::JQuery::Function::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::JQuery::Function');
}

# -----------------------------------------------------------------------------

package main;
Quiq::JQuery::Function::Test->runTests;

# eof
