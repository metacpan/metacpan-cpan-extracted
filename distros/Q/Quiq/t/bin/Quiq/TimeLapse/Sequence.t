#!/usr/bin/env perl

package Quiq::TimeLapse::Sequence::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::TimeLapse::Sequence');
}

# -----------------------------------------------------------------------------

package main;
Quiq::TimeLapse::Sequence::Test->runTests;

# eof
