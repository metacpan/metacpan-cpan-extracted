#!/usr/bin/env perl

package Quiq::Logger::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Logger');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Logger::Test->runTests;

# eof
