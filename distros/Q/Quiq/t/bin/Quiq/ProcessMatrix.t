#!/usr/bin/env perl

package Quiq::ProcessMatrix::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ProcessMatrix');
}

# -----------------------------------------------------------------------------

package main;
Quiq::ProcessMatrix::Test->runTests;

# eof
