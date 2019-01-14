#!/usr/bin/env perl

package Quiq::TimeLapse::Directory::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::TimeLapse::Directory');
}

# -----------------------------------------------------------------------------

package main;
Quiq::TimeLapse::Directory::Test->runTests;

# eof
