#!/usr/bin/env perl

package Quiq::Axis::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Axis');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Axis::Test->runTests;

# eof
