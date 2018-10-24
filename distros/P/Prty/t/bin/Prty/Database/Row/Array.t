#!/usr/bin/env perl

package Prty::Database::Row::Array::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Database::Row::Array');
}

# -----------------------------------------------------------------------------

sub test_new : Test(4) {
    my $self = shift;

    my @titles = qw/a b c/;
    my @values = qw/1 2 3/;

    my $obj = Prty::Database::Row::Array->new(\@values);
    $self->is(ref($obj),'Prty::Database::Row::Array');
    $self->isDeeply($obj,\@values);

    $obj = Prty::Database::Row::Array->new(\@titles,\@values);
    $self->is(ref($obj),'Prty::Database::Row::Array');
    $self->isDeeply($obj,\@values);
}

# -----------------------------------------------------------------------------

package main;
Prty::Database::Row::Array::Test->runTests;

# eof
