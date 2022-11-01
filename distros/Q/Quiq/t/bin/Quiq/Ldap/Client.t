#!/usr/bin/env perl

package Quiq::Ldap::Client::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Ldap::Client');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Ldap::Client::Test->runTests;

# eof
