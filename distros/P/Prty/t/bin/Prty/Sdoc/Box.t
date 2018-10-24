#!/usr/bin/env perl

package Prty::Sdoc::Box::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::Box');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::Box::Test->runTests;

# eof
