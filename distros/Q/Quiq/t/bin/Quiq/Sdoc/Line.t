#!/usr/bin/env perl

package Quiq::Sdoc::Line::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sdoc::Line');
}

# -----------------------------------------------------------------------------

sub test_type : Test(2) {
    my $self = shift;

    # Section

    my $ln = Quiq::Sdoc::Line->new('== Description',47,\'[testfile]');
    my $type = $ln->type;
    $self->is($type,'Section','type: type');

    # Item

    $ln = Quiq::Sdoc::Line->new('* Test',47,\'[testfile]');
    $type = $ln->type;
    $self->is($type,'Item','type: type');
}

# -----------------------------------------------------------------------------

sub test_item : Test(4) {
    my $self = shift;

    my $ln = Quiq::Sdoc::Line->new('* XXX',47,\'[testfile]');
    my ($type,$label,$indent,$text) = $ln->item;
    $self->is($type,'*','item: * type');
    $self->is($label,'*','item: * label');
    $self->is($indent,2,'item: * indent');
    $self->is($text,'  XXX','item: * text');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sdoc::Line::Test->runTests;

# eof
