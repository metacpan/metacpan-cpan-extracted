#!/usr/bin/env perl

package Quiq::Gd::Graphic::BlockDiagram::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Gd::Graphic::BlockDiagram');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Gd::Graphic::BlockDiagram::Test->runTests;

# eof
