#!/usr/bin/env perl

package Quiq::AxisTick::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::AxisTick');
}

# -----------------------------------------------------------------------------

package main;
Quiq::AxisTick::Test->runTests;

# eof
