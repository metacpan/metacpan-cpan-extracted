#!/usr/bin/env perl

package Quiq::Zugferd2::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Zugferd2');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Zugferd2::Test->runTests;

# eof
