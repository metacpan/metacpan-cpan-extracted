#!/usr/bin/env perl

package Quiq::If::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::If');
}

# -----------------------------------------------------------------------------

sub test_catIf : Test(2) {
    my $self = shift;

    my $str = Quiq::If->catIf(0,sub {'Dies','ist','ein',undef,'Test'});
    $self->is($str,'');

    $str = Quiq::If->catIf(1,sub {'Dies','ist','ein',undef,'Test'});
    $self->is($str,'DiesisteinTest');
}

# -----------------------------------------------------------------------------

sub test_listIf : Test(2) {
    my $self = shift;

    my @ret = Quiq::If->listIf(0,sub {'Dies','ist','ein','Test'});
    $self->isDeeply(\@ret,[]);

    @ret = Quiq::If->listIf(1,sub {'Dies','ist','ein','Test'});
    $self->isDeeply(\@ret,['Dies','ist','ein','Test']);
}

# -----------------------------------------------------------------------------

package main;
Quiq::If::Test->runTests;

# eof
