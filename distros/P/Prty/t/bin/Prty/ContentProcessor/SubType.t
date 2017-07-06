#!/usr/bin/env perl

package Prty::ContentProcessor::SubType::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::ContentProcessor::SubType');
}

# -----------------------------------------------------------------------------

package main;
Prty::ContentProcessor::SubType::Test->runTests;

# eof
