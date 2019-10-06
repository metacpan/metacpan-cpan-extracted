#!/usr/bin/env perl

package Quiq::PostgreSql::Catalog::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::PostgreSql::Catalog');
}

# -----------------------------------------------------------------------------

package main;
Quiq::PostgreSql::Catalog::Test->runTests;

# eof
