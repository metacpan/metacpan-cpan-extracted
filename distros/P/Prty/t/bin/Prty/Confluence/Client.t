#!/usr/bin/env perl

package Prty::Confluence::Client::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Confluence::Client');
}

# -----------------------------------------------------------------------------

package main;
Prty::Confluence::Client::Test->runTests;

# eof
