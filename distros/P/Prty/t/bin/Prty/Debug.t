#!/usr/bin/env perl

package Prty::Debug::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Debug');
}

# -----------------------------------------------------------------------------

sub test_modulePaths : Test(1) {
    my $self = shift;

    my $str = Prty::Debug->modulePaths;
    $self->like($str,qr|Prty/Debug|);
}

# -----------------------------------------------------------------------------

package main;
Prty::Debug::Test->runTests;

# eof
