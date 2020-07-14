#!/usr/bin/env perl

package Quiq::PlotlyJs::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::PlotlyJs');
}

# -----------------------------------------------------------------------------

package main;
Quiq::PlotlyJs::Test->runTests;

# eof
