#!/usr/bin/env perl

package Prty::Http::Message::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Http::Message');
}

# -----------------------------------------------------------------------------

package main;
Prty::Http::Message::Test->runTests;

# eof
