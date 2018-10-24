#!/usr/bin/env perl

package Prty::Fibu::Buchung::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Fibu::Buchung');
}

# -----------------------------------------------------------------------------

package main;
Prty::Fibu::Buchung::Test->runTests;

# eof
