#!/usr/bin/env perl

package Quiq::TableRow::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::TableRow');
}

# -----------------------------------------------------------------------------

package main;
Quiq::TableRow::Test->runTests;

# eof
