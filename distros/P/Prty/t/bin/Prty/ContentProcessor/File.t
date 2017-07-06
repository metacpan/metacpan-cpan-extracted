#!/usr/bin/env perl

package Prty::ContentProcessor::File::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::ContentProcessor::File');
}

# -----------------------------------------------------------------------------

package main;
Prty::ContentProcessor::File::Test->runTests;

# eof
