#!/usr/bin/env perl

package Quiq::Sdoc::Node::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sdoc::Node');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sdoc::Node::Test->runTests;

# eof
