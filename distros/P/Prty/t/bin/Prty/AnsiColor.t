#!/usr/bin/env perl

package Prty::AnsiColor::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::AnsiColor');
}

# -----------------------------------------------------------------------------

package main;
Prty::AnsiColor::Test->runTests;

# eof
