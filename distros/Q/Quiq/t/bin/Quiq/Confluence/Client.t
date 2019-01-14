#!/usr/bin/env perl

package Quiq::Confluence::Client::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Confluence::Client');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Confluence::Client::Test->runTests;

# eof
