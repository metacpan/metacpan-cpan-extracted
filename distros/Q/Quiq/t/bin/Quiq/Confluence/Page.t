#!/usr/bin/env perl

package Quiq::Confluence::Page::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Confluence::Page');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Confluence::Page::Test->runTests;

# eof
