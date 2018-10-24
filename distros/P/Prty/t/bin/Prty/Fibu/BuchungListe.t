#!/usr/bin/env perl

package Prty::Fibu::BuchungListe::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Fibu::BuchungListe');
}

# -----------------------------------------------------------------------------

package main;
Prty::Fibu::BuchungListe::Test->runTests;

# eof
