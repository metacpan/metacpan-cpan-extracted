#!/usr/bin/env perl

package Quiq::Net::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Net');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Net::Test->runTests;

# eof
