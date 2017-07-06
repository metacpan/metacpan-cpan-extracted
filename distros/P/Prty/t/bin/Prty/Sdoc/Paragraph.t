#!/usr/bin/env perl

package Prty::Sdoc::Paragraph::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::Paragraph');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::Paragraph::Test->runTests;

# eof
