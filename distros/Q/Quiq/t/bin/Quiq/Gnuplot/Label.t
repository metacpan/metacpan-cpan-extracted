#!/usr/bin/env perl

package Quiq::Gnuplot::Label::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Gnuplot::Label');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Gnuplot::Label::Test->runTests;

# eof
