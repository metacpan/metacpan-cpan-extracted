#!/usr/bin/env perl

package Quiq::Http::Client::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Http::Client');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Http::Client::Test->runTests;

# eof
