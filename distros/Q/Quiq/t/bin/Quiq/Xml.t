#!/usr/bin/env perl

package Quiq::Xml::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Xml');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Xml::Test->runTests;

# eof
