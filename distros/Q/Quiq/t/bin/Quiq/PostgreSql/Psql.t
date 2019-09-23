#!/usr/bin/env perl

package Quiq::PostgreSql::Psql::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::PostgreSql::Psql');
}

# -----------------------------------------------------------------------------

package main;
Quiq::PostgreSql::Psql::Test->runTests;

# eof
