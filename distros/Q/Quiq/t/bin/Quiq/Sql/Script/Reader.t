#!/usr/bin/env perl

package Quiq::Sql::Script::Reader::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sql::Script::Reader');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sql::Script::Reader::Test->runTests;

# eof
