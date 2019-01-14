#!/usr/bin/env perl

package Quiq::MediaWiki::Api::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::MediaWiki::Api');
}

# -----------------------------------------------------------------------------

package main;
Quiq::MediaWiki::Api::Test->runTests;

# eof
