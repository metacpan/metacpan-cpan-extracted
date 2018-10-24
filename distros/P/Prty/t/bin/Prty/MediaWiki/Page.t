#!/usr/bin/env perl

package Prty::MediaWiki::Page::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::MediaWiki::Page');
}

# -----------------------------------------------------------------------------

package main;
Prty::MediaWiki::Page::Test->runTests;

# eof
