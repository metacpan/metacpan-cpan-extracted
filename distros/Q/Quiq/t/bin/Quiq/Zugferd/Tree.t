#!/usr/bin/env perl

package Quiq::Zugferd::Tree::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Zugferd::Tree');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Zugferd::Tree::Test->runTests;

# eof
