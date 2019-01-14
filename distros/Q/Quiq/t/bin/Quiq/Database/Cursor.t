#!/usr/bin/env perl

package Quiq::Database::Cursor::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Database::Cursor');
}

# -----------------------------------------------------------------------------

sub test_new : Test(17) {
    my $self = shift;

    my $cur = Quiq::Database::Cursor->new;
    $self->is(ref($cur),'Quiq::Database::Cursor');
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
    #     'Quiq::Database::Row::Object','new: rowClass (get)';
    # $self->is($cur->rowClass,
    #     'Quiq::Database::Row::Object','new: rowClass';

    $self->ok($cur->get('startTime'));
    $self->ok($cur->startTime);

    $self->is($cur->get('execTime'),0);
    $self->is($cur->execTime,0);

    $cur->close;
    $self->is($cur,undef);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Database::Cursor::Test->runTests;

# eof
