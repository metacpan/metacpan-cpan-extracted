#!/usr/bin/env perl

package Quiq::Html::Base::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Base');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Base::Test->runTests;

# eof
