#!/usr/bin/env perl

package Quiq::Progress::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Progress');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Progress::Test->runTests;

# eof
