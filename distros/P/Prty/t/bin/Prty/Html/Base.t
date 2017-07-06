#!/usr/bin/env perl

package Prty::Html::Base::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Base');
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Base::Test->runTests;

# eof
