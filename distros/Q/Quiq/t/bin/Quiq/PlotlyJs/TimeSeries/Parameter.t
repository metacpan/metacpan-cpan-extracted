#!/usr/bin/env perl

package Quiq::PlotlyJs::TimeSeries::Parameter::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::PlotlyJs::TimeSeries::Parameter');
}

# -----------------------------------------------------------------------------

package main;
Quiq::PlotlyJs::TimeSeries::Parameter::Test->runTests;

# eof
