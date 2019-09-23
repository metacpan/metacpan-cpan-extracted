#!/usr/bin/env perl

package Quiq::Concat::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Concat');
}

# -----------------------------------------------------------------------------

sub test_catIf : Test(2) {
    my $self = shift;

    my $str = Quiq::Concat->catIf(0,sub {'Dies','ist','ein',undef,'Test'});
    $self->is($str,'');

    $str = Quiq::Concat->catIf(1,sub {'Dies','ist','ein',undef,'Test'});
    $self->is($str,'DiesisteinTest');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Concat::Test->runTests;

# eof
