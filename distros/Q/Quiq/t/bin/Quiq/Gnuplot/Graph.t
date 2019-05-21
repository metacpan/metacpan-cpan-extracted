#!/usr/bin/env perl

package Quiq::Gnuplot::Graph::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Gnuplot::Graph');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Gnuplot::Graph::Test->runTests;

# eof
