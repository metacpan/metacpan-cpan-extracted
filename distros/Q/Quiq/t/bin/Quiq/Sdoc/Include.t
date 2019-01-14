#!/usr/bin/env perl

package Quiq::Sdoc::Include::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sdoc::Include');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sdoc::Include::Test->runTests;

# eof
