#!/usr/bin/env perl

package Prty::JQuery::Function::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::JQuery::Function');
}

# -----------------------------------------------------------------------------

package main;
Prty::JQuery::Function::Test->runTests;

# eof
