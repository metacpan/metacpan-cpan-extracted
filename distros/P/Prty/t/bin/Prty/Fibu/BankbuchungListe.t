#!/usr/bin/env perl

package Prty::Fibu::BankbuchungListe::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Fibu::BankbuchungListe');
}

# -----------------------------------------------------------------------------

package main;
Prty::Fibu::BankbuchungListe::Test->runTests;

# eof
