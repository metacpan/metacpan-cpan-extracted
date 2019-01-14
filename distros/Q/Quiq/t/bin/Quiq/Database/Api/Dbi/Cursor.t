#!/usr/bin/env perl

package Quiq::Database::Api::Dbi::Cursor::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Database::Api::Dbi::Cursor');
}

# -----------------------------------------------------------------------------

sub test_new : Test(6) {
    my $self = shift;

    my $cur = Quiq::Database::Api::Dbi::Cursor->new;
    $self->is(ref($cur),'Quiq::Database::Api::Dbi::Cursor');
    $self->is($cur->get('sth'),undef);
    $self->is($cur->get('bindVars'),0,);
    $self->isDeeply($cur->get('titles'),[]);
    $self->is($cur->get('hits'),0);
    $self->is($cur->get('id'),0);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Database::Api::Dbi::Cursor::Test->runTests;

# eof
