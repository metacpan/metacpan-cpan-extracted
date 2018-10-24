#!/usr/bin/env perl

package Prty::TimeLapse::Directory::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::TimeLapse::Directory');
}

# -----------------------------------------------------------------------------

package main;
Prty::TimeLapse::Directory::Test->runTests;

# eof
