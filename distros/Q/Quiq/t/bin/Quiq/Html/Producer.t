#!/usr/bin/env perl

package Quiq::Html::Producer::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Producer');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Producer::Test->runTests;

# eof
