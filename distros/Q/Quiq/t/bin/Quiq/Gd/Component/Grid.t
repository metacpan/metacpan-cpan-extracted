#!/usr/bin/env perl

package Quiq::Gd::Component::Grid::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Gd::Component::Grid');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Gd::Component::Grid::Test->runTests;

# eof
