#!/usr/bin/env perl

package Prty::TimeLapse::RangeDef::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::TimeLapse::RangeDef');
}

# -----------------------------------------------------------------------------

package main;
Prty::TimeLapse::RangeDef::Test->runTests;

# eof
