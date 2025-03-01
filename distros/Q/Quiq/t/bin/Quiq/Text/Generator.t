#!/usr/bin/env perl

package Quiq::Text::Generator::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Text::Generator');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Text::Generator::Test->runTests;

# eof
