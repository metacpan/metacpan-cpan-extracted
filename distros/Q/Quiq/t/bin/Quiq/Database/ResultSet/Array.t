#!/usr/bin/env perl

package Quiq::Database::ResultSet::Array::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Database::ResultSet::Array');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Database::ResultSet::Array::Test->runTests;

# eof
