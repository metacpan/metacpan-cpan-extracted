#!/usr/bin/env perl

package Prty::Sdoc::List::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::List');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::List::Test->runTests;

# eof
