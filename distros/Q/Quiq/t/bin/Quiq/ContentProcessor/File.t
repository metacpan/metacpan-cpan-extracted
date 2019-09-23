#!/usr/bin/env perl

package Quiq::ContentProcessor::File::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ContentProcessor::File');
}

# -----------------------------------------------------------------------------

package main;
Quiq::ContentProcessor::File::Test->runTests;

# eof
