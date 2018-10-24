#!/usr/bin/env perl

package Prty::Sdoc::KeyValTable::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::KeyValTable');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::KeyValTable::Test->runTests;

# eof
