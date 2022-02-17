#!/usr/bin/env perl

package Quiq::MailTo::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::MailTo');
}

# -----------------------------------------------------------------------------

package main;
Quiq::MailTo::Test->runTests;

# eof
