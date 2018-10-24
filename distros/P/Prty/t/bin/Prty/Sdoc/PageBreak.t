#!/usr/bin/env perl

package Prty::Sdoc::PageBreak::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::PageBreak');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::PageBreak::Test->runTests;

# eof
