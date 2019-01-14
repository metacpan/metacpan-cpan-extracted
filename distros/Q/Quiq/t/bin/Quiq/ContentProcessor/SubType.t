#!/usr/bin/env perl

package Quiq::ContentProcessor::SubType::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ContentProcessor::SubType');
}

# -----------------------------------------------------------------------------

package main;
Quiq::ContentProcessor::SubType::Test->runTests;

# eof
