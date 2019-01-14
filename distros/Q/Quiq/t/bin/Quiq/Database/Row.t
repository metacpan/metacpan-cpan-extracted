#!/usr/bin/env perl

package Quiq::Database::Row::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Database::Row');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Database::Row::Test->runTests;

# eof
