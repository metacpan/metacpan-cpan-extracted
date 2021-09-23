#!/usr/bin/env perl

package Quiq::Trash::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Trash');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Trash::Test->runTests;

# eof
