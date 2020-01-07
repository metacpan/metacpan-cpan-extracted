#!/usr/bin/env perl

package Quiq::PlotlyJs::Reference::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::PlotlyJs::Reference');
}

# -----------------------------------------------------------------------------

package main;
Quiq::PlotlyJs::Reference::Test->runTests;

# eof
