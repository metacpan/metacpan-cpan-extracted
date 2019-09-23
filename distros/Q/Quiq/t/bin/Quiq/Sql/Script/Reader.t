#!/usr/bin/env perl

package Quiq::Sql::Script::Reader::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sql::Script::Reader');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sql::Script::Reader::Test->runTests;

# eof
