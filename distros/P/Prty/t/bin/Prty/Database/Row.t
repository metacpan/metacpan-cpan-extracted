#!/usr/bin/env perl

package Prty::Database::Row::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Database::Row');
}

# -----------------------------------------------------------------------------

package main;
Prty::Database::Row::Test->runTests;

# eof
