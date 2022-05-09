#!/usr/bin/env perl

package Quiq::Smb::Client::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Smb::Client');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Smb::Client::Test->runTests;

# eof
