#!/usr/bin/env perl

package Quiq::Mojolicious::Plugin::Log::Parameters::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Mojolicious::Plugin::Log::Parameters');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Mojolicious::Plugin::Log::Parameters::Test->runTests;

# eof
