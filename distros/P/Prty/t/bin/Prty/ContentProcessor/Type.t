#!/usr/bin/env perl

package Prty::ContentProcessor::Type::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::ContentProcessor::Type');
}

# -----------------------------------------------------------------------------

package main;
Prty::ContentProcessor::Type::Test->runTests;

# eof
