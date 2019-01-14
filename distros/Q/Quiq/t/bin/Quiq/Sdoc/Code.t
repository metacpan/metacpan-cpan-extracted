#!/usr/bin/env perl

package Quiq::Sdoc::Code::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sdoc::Code');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sdoc::Code::Test->runTests;

# eof
