#!/usr/bin/env perl

package Prty::Confluence::Page::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Confluence::Page');
}

# -----------------------------------------------------------------------------

package main;
Prty::Confluence::Page::Test->runTests;

# eof
