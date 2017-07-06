#!/usr/bin/env perl

package Prty::Sdoc::Quote::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::Quote');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::Quote::Test->runTests;

# eof
