#!/usr/bin/env perl

package Quiq::Chrome::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Chrome');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Chrome::Test->runTests;

# eof
