#!/usr/bin/env perl

package Prty::ImagePool::Directory::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::ImagePool::Directory');
}

# -----------------------------------------------------------------------------

package main;
Prty::ImagePool::Directory::Test->runTests;

# eof
