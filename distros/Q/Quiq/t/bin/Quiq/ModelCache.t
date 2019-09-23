#!/usr/bin/env perl

package Quiq::ModelCache::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ModelCache');
}

# -----------------------------------------------------------------------------

package main;
Quiq::ModelCache::Test->runTests;

# eof
