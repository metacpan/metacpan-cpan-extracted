#!/usr/bin/env perl

package Prty::MediaWiki::Api::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::MediaWiki::Api');
}

# -----------------------------------------------------------------------------

package main;
Prty::MediaWiki::Api::Test->runTests;

# eof
