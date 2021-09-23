#!/usr/bin/env perl

package Quiq::Eog::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Eog');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Eog::Test->runTests;

# eof
