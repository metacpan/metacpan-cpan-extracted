#!/usr/bin/env perl

package Prty::Sdoc::Line::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Sdoc::Line');
}

# -----------------------------------------------------------------------------

sub test_type : Test(2) {
    my $self = shift;

    # Section

    my $ln = Prty::Sdoc::Line->new('== Description',47);
    my $type = $ln->type;
    $self->is($type,'Section','type: type');

    # Item

    $ln = Prty::Sdoc::Line->new('* Test',47);
    $type = $ln->type;
    $self->is($type,'Item','type: type');
}

# -----------------------------------------------------------------------------

sub test_item : Test(4) {
    my $self = shift;

    my $ln = Prty::Sdoc::Line->new('* XXX',47);
    my ($type,$label,$indent,$text) = $ln->item;
    $self->is($type,'*','item: * type');
    $self->is($label,'*','item: * label');
    $self->is($indent,2,'item: * indent');
    $self->is($text,'  XXX','item: * text');
}

# -----------------------------------------------------------------------------

package main;
Prty::Sdoc::Line::Test->runTests;

# eof
