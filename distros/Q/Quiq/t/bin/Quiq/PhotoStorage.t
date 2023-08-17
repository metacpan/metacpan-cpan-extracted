#!/usr/bin/env perl

package Quiq::PhotoStorage::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::PhotoStorage');
}

# -----------------------------------------------------------------------------

package main;
Quiq::PhotoStorage::Test->runTests;

# eof
