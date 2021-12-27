#!/usr/bin/env perl

package Quiq::ExportFile::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ExportFile');
}

# -----------------------------------------------------------------------------

package main;
Quiq::ExportFile::Test->runTests;

# eof
