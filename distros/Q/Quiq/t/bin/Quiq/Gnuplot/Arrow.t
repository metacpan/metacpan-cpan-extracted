#!/usr/bin/env perl

package Quiq::Gnuplot::Arrow::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Gnuplot::Arrow');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Gnuplot::Arrow::Test->runTests;

# eof
