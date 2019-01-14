#!/usr/bin/env perl

package Quiq::Fibu::Bankbuchung::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Fibu::Bankbuchung');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Fibu::Bankbuchung::Test->runTests;

# eof
