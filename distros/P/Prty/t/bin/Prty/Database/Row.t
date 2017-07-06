#!/usr/bin/env perl

package Prty::Database::Row::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Database::Row');
}

# -----------------------------------------------------------------------------

package main;
Prty::Database::Row::Test->runTests;

# eof
