#!/usr/bin/env perl

package Quiq::Http::Message::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Http::Message');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Http::Message::Test->runTests;

# eof
