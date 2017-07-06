#!/usr/bin/env perl

package Prty::Progress::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Progress');
}

# -----------------------------------------------------------------------------

package main;
Prty::Progress::Test->runTests;

# eof
