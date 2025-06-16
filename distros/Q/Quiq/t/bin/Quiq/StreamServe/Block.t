#!/usr/bin/env perl

package Quiq::StreamServe::Block::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::StreamServe::Block');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(2) {
    my $self = shift;

    my $ssb = Quiq::StreamServe::Block->new('0L');
    $self->is(ref($ssb),'Quiq::StreamServe::Block');

    $ssb->set('0LUBITNO'=>'PRN800334');
    my $val = $ssb->get('0LUBITNO');
    $self->is($val,'PRN800334');
}

# -----------------------------------------------------------------------------

package main;
Quiq::StreamServe::Block::Test->runTests;

# eof
