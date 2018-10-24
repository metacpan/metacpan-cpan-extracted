#!/usr/bin/env perl

package Prty::ContentProcessor::BaseType::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::ContentProcessor::BaseType');
}

# -----------------------------------------------------------------------------

package main;
Prty::ContentProcessor::BaseType::Test->runTests;

# eof
