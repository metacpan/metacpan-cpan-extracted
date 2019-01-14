#!/usr/bin/env perl

package Quiq::Sdoc::Link::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sdoc::Link');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sdoc::Link::Test->runTests;

# eof
