#!/usr/bin/env perl

package Prty::Http::Client::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Http::Client');
}

# -----------------------------------------------------------------------------

package main;
Prty::Http::Client::Test->runTests;

# eof
