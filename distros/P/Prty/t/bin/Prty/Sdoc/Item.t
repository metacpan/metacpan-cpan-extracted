#!/usr/bin/env perl

package Prty::Sdoc::Item::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::Item');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::Item::Test->runTests;

# eof
