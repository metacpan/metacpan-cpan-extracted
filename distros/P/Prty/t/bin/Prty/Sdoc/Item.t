#!/usr/bin/env perl

package Prty::Sdoc::Item::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::Item');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::Item::Test->runTests;

# eof
