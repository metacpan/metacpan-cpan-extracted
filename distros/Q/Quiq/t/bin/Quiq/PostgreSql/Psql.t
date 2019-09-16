#!/usr/bin/env perl

package Quiq::PostgreSql::Psql::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::PostgreSql::Psql');
}

# -----------------------------------------------------------------------------

package main;
Quiq::PostgreSql::Psql::Test->runTests;

# eof
