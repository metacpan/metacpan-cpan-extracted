#!/usr/bin/env perl

package Prty::ImagePool::Sequence::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::ImagePool::Sequence');
}

# -----------------------------------------------------------------------------

package main;
Prty::ImagePool::Sequence::Test->runTests;

# eof
