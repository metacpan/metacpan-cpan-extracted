#!/usr/bin/env perl

package Quiq::Fibu::BankbuchungListe::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Fibu::BankbuchungListe');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Fibu::BankbuchungListe::Test->runTests;

# eof
