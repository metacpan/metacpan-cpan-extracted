#!/usr/bin/env perl

package Prty::AnsiColor::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::AnsiColor');
}

# -----------------------------------------------------------------------------

package main;
Prty::AnsiColor::Test->runTests;

# eof
