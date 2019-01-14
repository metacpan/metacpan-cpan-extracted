#!/usr/bin/env perl

package Quiq::Sdoc::Box::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sdoc::Box');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sdoc::Box::Test->runTests;

# eof
