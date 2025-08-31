#!/usr/bin/env perl

package Quiq::Zugferd::Entity::Rechnung::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Zugferd::Entity::Rechnung');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Zugferd::Entity::Rechnung::Test->runTests;

# eof
