#!/usr/bin/env perl

package Prty::Epoch::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Epoch');
}

# -----------------------------------------------------------------------------

sub test_new : Test(3) {
    my $self = shift;

    # ohne Parameter
    
    my $t = Prty::Epoch->new;
    $self->is(ref($t),'Prty::Epoch');
    $self->ok($$t >= time);

    # mit Parameter

    $t = Prty::Epoch->new(12345678);
    $self->is($$t,12345678);
}

# -----------------------------------------------------------------------------

sub test_epoch : Test(1) {
    my $self = shift;

    my $epoch = Prty::Epoch->new->epoch;
    $self->ok($epoch >= time);
}

# -----------------------------------------------------------------------------

sub test_as : Test(1) {
    my $self = shift;

    $ENV{'TZ'} = 'CET'; # Fix: CPAN Testers

    my $str = Prty::Epoch->new(1464342621.73231)->as('YYYY-MM-DD HH:MI:SS');
    $self->is($str,'2016-05-27 11:50:21');
}

# -----------------------------------------------------------------------------

package main;
Prty::Epoch::Test->runTests;

# eof
