#!/usr/bin/env perl

package Quiq::ContentProcessor::File::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ContentProcessor::File');
}

# -----------------------------------------------------------------------------

package main;
Quiq::ContentProcessor::File::Test->runTests;

# eof
