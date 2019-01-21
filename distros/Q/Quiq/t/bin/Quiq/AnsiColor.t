#!/usr/bin/env perl

package Quiq::AnsiColor::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::AnsiColor');
}

# -----------------------------------------------------------------------------

sub test_active_root: Test(3) {
    my $self = shift;

    my $a = Quiq::AnsiColor->new;
    my $bool = $a->active;
    $self->is($bool,1);

    $a = Quiq::AnsiColor->new(0);
    $bool = $a->active;
    $self->is($bool,0);

    $a = Quiq::AnsiColor->new(1);
    $bool = $a->active;
    $self->is($bool,1);
}

# -----------------------------------------------------------------------------

package main;
Quiq::AnsiColor::Test->runTests;

# eof
