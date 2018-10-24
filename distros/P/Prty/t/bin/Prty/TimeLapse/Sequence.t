#!/usr/bin/env perl

package Prty::TimeLapse::Sequence::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::TimeLapse::Sequence');
}

# -----------------------------------------------------------------------------

package main;
Prty::TimeLapse::Sequence::Test->runTests;

# eof
