#!/usr/bin/env perl

package Prty::Concat::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Concat');
}

# -----------------------------------------------------------------------------

sub test_catIf : Test(2) {
    my $self = shift;

    my $str = Prty::Concat->catIf(0,sub {'Dies','ist','ein',undef,'Test'});
    $self->is($str,'');

    $str = Prty::Concat->catIf(1,sub {'Dies','ist','ein',undef,'Test'});
    $self->is($str,'DiesisteinTest');
}

# -----------------------------------------------------------------------------

package main;
Prty::Concat::Test->runTests;

# eof
