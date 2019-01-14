#!/usr/bin/env perl

package Quiq::ImagePool::Directory::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ImagePool::Directory');
}

# -----------------------------------------------------------------------------

package main;
Quiq::ImagePool::Directory::Test->runTests;

# eof
