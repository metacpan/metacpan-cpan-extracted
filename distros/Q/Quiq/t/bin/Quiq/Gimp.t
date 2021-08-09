#!/usr/bin/env perl

package Quiq::Gimp::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Gimp');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Gimp::Test->runTests;

# eof
