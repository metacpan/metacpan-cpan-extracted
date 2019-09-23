#!/usr/bin/env perl

package Quiq::Ssh::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Ssh');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Ssh::Test->runTests;

# eof
