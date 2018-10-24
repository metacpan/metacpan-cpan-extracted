#!/usr/bin/env perl

package Prty::Sdoc::Row::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::Row');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::Row::Test->runTests;

# eof
