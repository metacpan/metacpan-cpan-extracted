#!/usr/bin/env perl

package Prty::File::Audio::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::File::Audio');
}

# -----------------------------------------------------------------------------

package main;
Prty::File::Audio::Test->runTests;

# eof
