#!/usr/bin/env perl

package Prty::Database::Cursor::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Database::Cursor');
}

# -----------------------------------------------------------------------------

sub test_new : Test(17) {
    my $self = shift;

    my $cur = Prty::Database::Cursor->new;
    $self->is(ref($cur),'Prty::Database::Cursor');
    $self->is($cur->get('apiCur'),undef);

    $self->is($cur->get('bindVars'),0);
    $self->is($cur->bindVars,0);

    $self->is($cur->get('db'),undef);
    $self->is($cur->db,undef);

    $self->is($cur->get('hits'),0);
    $self->is($cur->hits,0);

    $self->isDeeply($cur->get('titles'),[]);
    $self->isDeeply(scalar($cur->titles),[]);

    $self->is($cur->get('id'),0);
    $self->is($cur->id,0);

    # $self->is($cur->get('rowClass'),
    #     'Prty::Database::Row::Object','new: rowClass (get)';
    # $self->is($cur->rowClass,
    #     'Prty::Database::Row::Object','new: rowClass';

    $self->ok($cur->get('startTime'));
    $self->ok($cur->startTime);

    $self->is($cur->get('execTime'),0);
    $self->is($cur->execTime,0);

    $cur->close;
    $self->is($cur,undef);
}

# -----------------------------------------------------------------------------

package main;
Prty::Database::Cursor::Test->runTests;

# eof
