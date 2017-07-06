#!/usr/bin/env perl

package Prty::Database::Api::Dbi::Cursor::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Database::Api::Dbi::Cursor');
}

# -----------------------------------------------------------------------------

sub test_new : Test(6) {
    my $self = shift;

    my $cur = Prty::Database::Api::Dbi::Cursor->new;
    $self->is(ref($cur),'Prty::Database::Api::Dbi::Cursor');
    $self->is($cur->get('sth'),undef);
    $self->is($cur->get('bindVars'),0,);
    $self->isDeeply($cur->get('titles'),[]);
    $self->is($cur->get('hits'),0);
    $self->is($cur->get('id'),0);
}

# -----------------------------------------------------------------------------

package main;
Prty::Database::Api::Dbi::Cursor::Test->runTests;

# eof
