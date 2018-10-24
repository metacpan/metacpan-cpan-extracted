#!/usr/bin/env perl

package Prty::Sdoc::Node::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::Node');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::Node::Test->runTests;

# eof
