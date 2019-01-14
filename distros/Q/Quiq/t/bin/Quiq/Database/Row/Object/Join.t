#!/usr/bin/env perl

package Quiq::Database::Row::Object::Join::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Database::Row::Object::Join');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Database::Row::Object::Join::Test->runTests;

# eof
