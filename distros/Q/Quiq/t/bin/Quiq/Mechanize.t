#!/usr/bin/env perl

package Quiq::Mechanize::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Mechanize');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Mechanize::Test->runTests;

# eof
