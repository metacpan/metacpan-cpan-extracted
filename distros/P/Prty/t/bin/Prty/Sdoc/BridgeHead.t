#!/usr/bin/env perl

package Prty::Sdoc::BridgeHead::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::BridgeHead');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::BridgeHead::Test->runTests;

# eof
