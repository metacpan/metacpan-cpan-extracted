#!/usr/bin/env perl

package Quiq::File::Audio::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::File::Audio');
}

# -----------------------------------------------------------------------------

package main;
Quiq::File::Audio::Test->runTests;

# eof
