#!/usr/bin/env perl

package Quiq::File::Audio::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::File::Audio');
}

# -----------------------------------------------------------------------------

package main;
Quiq::File::Audio::Test->runTests;

# eof
