#!/usr/bin/env perl

package Quiq::Database::Api::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Database::Api');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Database::Api::Test->runTests;

# eof
