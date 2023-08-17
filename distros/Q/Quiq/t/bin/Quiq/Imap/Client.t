#!/usr/bin/env perl

package Quiq::Imap::Client::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Imap::Client');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Imap::Client::Test->runTests;

# eof
