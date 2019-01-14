#!/usr/bin/env perl

package Quiq::Test::Class::Method::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Test::Class::Method');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Test::Class::Method::Test->runTests;

# eof
