#!/usr/bin/env perl

package Quiq::Zugferd::Entity::Verkaeufer::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Zugferd::Entity::Verkaeufer');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Zugferd::Entity::Verkaeufer::Test->runTests;

# eof
