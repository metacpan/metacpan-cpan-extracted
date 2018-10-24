#!/usr/bin/env perl

package Prty::Mojolicious::Plugin::Log::Parameters::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Mojolicious::Plugin::Log::Parameters');
}

# -----------------------------------------------------------------------------

package main;
Prty::Mojolicious::Plugin::Log::Parameters::Test->runTests;

# eof
