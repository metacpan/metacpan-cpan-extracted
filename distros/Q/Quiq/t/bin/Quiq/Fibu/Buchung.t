#!/usr/bin/env perl

package Quiq::Fibu::Buchung::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Fibu::Buchung');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Fibu::Buchung::Test->runTests;

# eof
