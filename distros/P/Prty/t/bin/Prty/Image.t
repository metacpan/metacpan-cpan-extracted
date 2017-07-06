#!/usr/bin/env perl

package Prty::Image::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Image');
}

# -----------------------------------------------------------------------------

package main;
Prty::Image::Test->runTests;

# eof
