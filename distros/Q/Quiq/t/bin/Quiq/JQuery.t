#!/usr/bin/env perl

package Quiq::JQuery::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::JQuery');
}

# -----------------------------------------------------------------------------

package main;
Quiq::JQuery::Test->runTests;

# eof
