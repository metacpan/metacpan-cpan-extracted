#!/usr/bin/env perl

package Quiq::Gnuplot::Label::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Gnuplot::Label');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Gnuplot::Label::Test->runTests;

# eof
