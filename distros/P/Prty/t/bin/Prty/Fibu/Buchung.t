#!/usr/bin/env perl

package Prty::Fibu::Buchung::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Fibu::Buchung');
}

# -----------------------------------------------------------------------------

package main;
Prty::Fibu::Buchung::Test->runTests;

# eof
