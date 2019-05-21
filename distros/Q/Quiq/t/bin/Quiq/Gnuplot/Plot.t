#!/usr/bin/env perl

package Quiq::Gnuplot::Plot::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Gnuplot::Plot');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Gnuplot::Plot::Test->runTests;

# eof
