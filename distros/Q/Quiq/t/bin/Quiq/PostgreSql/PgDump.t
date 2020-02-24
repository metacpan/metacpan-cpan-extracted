#!/usr/bin/env perl

package Quiq::PostgreSql::PgDump::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::PostgreSql::PgDump');
}

# -----------------------------------------------------------------------------

package main;
Quiq::PostgreSql::PgDump::Test->runTests;

# eof
