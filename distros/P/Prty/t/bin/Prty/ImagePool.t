#!/usr/bin/env perl

package Prty::ImagePool::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::ImagePool');
}

# -----------------------------------------------------------------------------

package main;
Prty::ImagePool::Test->runTests;

# eof
