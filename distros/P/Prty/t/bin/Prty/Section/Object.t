#!/usr/bin/env perl

package Prty::Section::Object::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Section::Object');
}

# -----------------------------------------------------------------------------

package main;
Prty::Section::Object::Test->runTests;

# eof
