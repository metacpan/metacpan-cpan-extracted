#!/usr/bin/env perl

package Quiq::Section::Object::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Section::Object');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Section::Object::Test->runTests;

# eof
