#!/usr/bin/env perl

package Quiq::Gd::Component::Axis::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Gd::Component::Axis');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Gd::Component::Axis::Test->runTests;

# eof
