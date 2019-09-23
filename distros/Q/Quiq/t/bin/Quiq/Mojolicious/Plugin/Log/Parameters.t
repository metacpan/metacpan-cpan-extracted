#!/usr/bin/env perl

package Quiq::Mojolicious::Plugin::Log::Parameters::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Mojolicious::Plugin::Log::Parameters');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Mojolicious::Plugin::Log::Parameters::Test->runTests;

# eof
