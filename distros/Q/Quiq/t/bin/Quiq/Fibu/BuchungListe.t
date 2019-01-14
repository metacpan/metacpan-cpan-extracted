#!/usr/bin/env perl

package Quiq::Fibu::BuchungListe::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Fibu::BuchungListe');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Fibu::BuchungListe::Test->runTests;

# eof
