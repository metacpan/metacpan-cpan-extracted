#!/usr/bin/env perl

package Quiq::Zugferd::Entity::Position::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Zugferd::Entity::Position');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Zugferd::Entity::Position::Test->runTests;

# eof
