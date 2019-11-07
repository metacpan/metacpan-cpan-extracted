#!/usr/bin/env perl

package Quiq::Axis::Time::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Gd::Font;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Axis::Time');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(7) {
    my $self = shift;

    my $ax = Quiq::Axis::Time->new(
        font => Quiq::Gd::Font->new('gdSmallFont'),
        length => 400,
        min => 0.001,
        max => 10_000,
        debug => 0,
    );
    $self->is(ref $ax,'Quiq::Axis::Time');

    $self->is($ax->get('orientation'),'x'); # Default
    $self->is($ax->get('font')->name,'gdSmallFont');
    $self->is($ax->get('length'),400);
    $self->is($ax->get('min'),0.001);
    $self->is($ax->get('max'),10000);
    $self->ok($ax->get('minTickGap')); # Default
}

# -----------------------------------------------------------------------------

package main;
Quiq::Axis::Time::Test->runTests;

# eof
