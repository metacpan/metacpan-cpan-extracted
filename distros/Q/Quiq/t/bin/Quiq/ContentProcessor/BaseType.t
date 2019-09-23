#!/usr/bin/env perl

package Quiq::ContentProcessor::BaseType::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ContentProcessor::BaseType');
}

# -----------------------------------------------------------------------------

package main;
Quiq::ContentProcessor::BaseType::Test->runTests;

# eof
