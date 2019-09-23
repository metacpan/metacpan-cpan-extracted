#!/usr/bin/env perl

package Quiq::ContentProcessor::SubType::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ContentProcessor::SubType');
}

# -----------------------------------------------------------------------------

package main;
Quiq::ContentProcessor::SubType::Test->runTests;

# eof
