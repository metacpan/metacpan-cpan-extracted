#!/usr/bin/env perl

package Quiq::Tree::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Tree');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Tree::Test->runTests;

# eof
