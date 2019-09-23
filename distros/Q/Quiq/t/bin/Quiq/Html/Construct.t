#!/usr/bin/env perl

package Quiq::Html::Construct::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Construct');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Construct::Test->runTests;

# eof
