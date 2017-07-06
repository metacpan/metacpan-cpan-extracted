#!/usr/bin/env perl

package Prty::TimeLapse::RangeDef::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::TimeLapse::RangeDef');
}

# -----------------------------------------------------------------------------

package main;
Prty::TimeLapse::RangeDef::Test->runTests;

# eof
