#!/usr/bin/env perl

package Quiq::XTerm::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::XTerm');
}

# -----------------------------------------------------------------------------

package main;
Quiq::XTerm::Test->runTests;

# eof
