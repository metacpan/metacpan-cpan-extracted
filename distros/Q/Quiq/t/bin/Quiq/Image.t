#!/usr/bin/env perl

package Quiq::Image::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Image');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Image::Test->runTests;

# eof
