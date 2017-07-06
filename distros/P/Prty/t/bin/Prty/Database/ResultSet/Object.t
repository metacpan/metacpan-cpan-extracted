#!/usr/bin/env perl

package Prty::Database::ResultSet::Object::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Database::ResultSet::Object');
}

# -----------------------------------------------------------------------------

package main;
Prty::Database::ResultSet::Object::Test->runTests;

# eof
