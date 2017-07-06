#!/usr/bin/env perl

package Prty::Sdoc::Table::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::Table');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::Table::Test->runTests;

# eof
