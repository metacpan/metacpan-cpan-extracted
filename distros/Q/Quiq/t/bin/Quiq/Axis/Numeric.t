#!/usr/bin/env perl

package Quiq::Axis::Numeric::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Gd::Font;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Axis::Numeric');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(8) {
    my $self = shift;

    my $ax = Quiq::Axis::Numeric->new(
        font => Quiq::Gd::Font->new('gdSmallFont'),
        length => 400,
        min => 0.001,
        max => 10_000,
        logarithmic => 1,
        debug => 0,
    );
    $self->is(ref $ax,'Quiq::Axis::Numeric');

    $self->is($ax->get('orientation'),'x'); # Default
    $self->is($ax->get('font')->name,'gdSmallFont');
    $self->is($ax->get('length'),400);
    $self->is($ax->get('min'),0.001);
    $self->is($ax->get('max'),10000);
    $self->is($ax->get('logarithmic'),1);
    $self->ok($ax->get('minTickGap')); # Default
}

# -----------------------------------------------------------------------------

package main;
Quiq::Axis::Numeric::Test->runTests;

# eof
