#!/usr/bin/env perl

package Quiq::Gd::Graphic::ColorLegend::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Gd::Graphic::ColorLegend');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Gd::Graphic::ColorLegend::Test->runTests;

# eof
