#!/usr/bin/env perl

package Prty::Database::Row::Object::Join::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Database::Row::Object::Join');
}

# -----------------------------------------------------------------------------

package main;
Prty::Database::Row::Object::Join::Test->runTests;

# eof
