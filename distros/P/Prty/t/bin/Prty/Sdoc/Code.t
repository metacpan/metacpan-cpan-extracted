#!/usr/bin/env perl

package Prty::Sdoc::Code::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::Code');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::Code::Test->runTests;

# eof
