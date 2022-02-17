#!/usr/bin/env perl

package Quiq::Web::Navigation::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Web::Navigation');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Web::Navigation::Test->runTests;

# eof
