#!/usr/bin/env perl

package Quiq::Database::Row::Object::Join::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Database::Row::Object::Join');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Database::Row::Object::Join::Test->runTests;

# eof
