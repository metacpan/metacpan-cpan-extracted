#!/usr/bin/env perl

package Quiq::ImagePool::Sequence::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ImagePool::Sequence');
}

# -----------------------------------------------------------------------------

package main;
Quiq::ImagePool::Sequence::Test->runTests;

# eof
