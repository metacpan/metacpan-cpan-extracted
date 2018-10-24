#!/usr/bin/env perl

package Prty::Database::Row::Object::Join::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Database::Row::Object::Join');
}

# -----------------------------------------------------------------------------

package main;
Prty::Database::Row::Object::Join::Test->runTests;

# eof
