#!/usr/bin/env perl

package Prty::Html::Util::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Util');
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Util::Test->runTests;

# eof
