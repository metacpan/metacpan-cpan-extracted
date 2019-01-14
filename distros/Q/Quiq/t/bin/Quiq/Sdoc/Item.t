#!/usr/bin/env perl

package Quiq::Sdoc::Item::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sdoc::Item');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sdoc::Item::Test->runTests;

# eof
