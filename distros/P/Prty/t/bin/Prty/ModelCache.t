#!/usr/bin/env perl

package Prty::ModelCache::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::ModelCache');
}

# -----------------------------------------------------------------------------

package main;
Prty::ModelCache::Test->runTests;

# eof
