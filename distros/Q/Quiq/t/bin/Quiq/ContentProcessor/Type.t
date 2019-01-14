#!/usr/bin/env perl

package Quiq::ContentProcessor::Type::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ContentProcessor::Type');
}

# -----------------------------------------------------------------------------

package main;
Quiq::ContentProcessor::Type::Test->runTests;

# eof
