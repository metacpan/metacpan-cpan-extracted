#!/usr/bin/env perl

package Quiq::Debug::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Debug');
}

# -----------------------------------------------------------------------------

sub test_modulePaths : Test(1) {
    my $self = shift;

    my $str = Quiq::Debug->modulePaths;
    $self->like($str,qr|Quiq/Debug|);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Debug::Test->runTests;

# eof
