#!/usr/bin/env perl

package Quiq::Confluence::Client::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Confluence::Client');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Confluence::Client::Test->runTests;

# eof
