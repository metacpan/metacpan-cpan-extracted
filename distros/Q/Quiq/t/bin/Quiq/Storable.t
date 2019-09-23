#!/usr/bin/env perl

package Quiq::Storable::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Storable');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(6) {
    my $self = shift;

    my $ser = Quiq::Storable->freeze({a=>1,b=>2,c=>3});
    my $ref = Quiq::Storable->thaw($ser);
    my @keys = sort keys %$ref;
    $self->isDeeply(\@keys,[qw/a b c/]);
    $self->is($ref->{'a'},1);
    $self->is($ref->{'b'},2);
    $self->is($ref->{'c'},3);

    my $clone = Quiq::Storable->clone($ref);
    $self->isnt($clone,$ref);
    $self->isDeeply($clone,$ref);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Storable::Test->runTests;

# eof
