#!/usr/bin/env perl

package Quiq::TimeLapse::Directory::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::TimeLapse::Directory');
}

# -----------------------------------------------------------------------------

package main;
Quiq::TimeLapse::Directory::Test->runTests;

# eof
