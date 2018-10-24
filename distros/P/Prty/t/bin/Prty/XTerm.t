#!/usr/bin/env perl

package Prty::XTerm::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::XTerm');
}

# -----------------------------------------------------------------------------

package main;
Prty::XTerm::Test->runTests;

# eof
