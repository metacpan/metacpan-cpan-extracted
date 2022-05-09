#!/usr/bin/env perl

package Quiq::Sftp::Client::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sftp::Client');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sftp::Client::Test->runTests;

# eof
