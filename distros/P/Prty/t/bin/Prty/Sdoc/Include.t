#!/usr/bin/env perl

package Prty::Sdoc::Include::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::Include');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::Include::Test->runTests;

# eof
