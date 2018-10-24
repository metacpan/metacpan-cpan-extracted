#!/usr/bin/env perl

package Prty::Sdoc::KeyValRow::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::KeyValRow');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::KeyValRow::Test->runTests;

# eof
