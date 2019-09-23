#!/usr/bin/env perl

package Quiq::Html::Util::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Util');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Util::Test->runTests;

# eof
