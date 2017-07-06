#!/usr/bin/env perl

package Prty::Sdoc::Figure::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::Figure');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::Figure::Test->runTests;

# eof
