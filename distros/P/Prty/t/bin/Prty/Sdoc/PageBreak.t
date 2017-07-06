#!/usr/bin/env perl

package Prty::Sdoc::PageBreak::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::PageBreak');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::PageBreak::Test->runTests;

# eof
