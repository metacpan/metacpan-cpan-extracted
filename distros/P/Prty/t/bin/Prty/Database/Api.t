#!/usr/bin/env perl

package Prty::Database::Api::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Database::Api');
}

# -----------------------------------------------------------------------------

package main;
Prty::Database::Api::Test->runTests;

# eof
