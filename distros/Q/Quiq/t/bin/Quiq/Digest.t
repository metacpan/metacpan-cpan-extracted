#!/usr/bin/env perl

package Quiq::Digest::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Digest');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Digest::Test->runTests;

# eof
