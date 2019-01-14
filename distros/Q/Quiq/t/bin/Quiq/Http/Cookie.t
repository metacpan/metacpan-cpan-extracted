#!/usr/bin/env perl

package Quiq::Http::Cookie::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Http::Cookie');
}

# -----------------------------------------------------------------------------

sub test_new : Test(2) {
    my $self = shift;

    my $cok = Quiq::Http::Cookie->new(sid=>4711);

    my $name = $cok->get('name');
    $self->is($name,'sid');

    my $value = $cok->get('value');
    $self->is($value,4711);
}

# -----------------------------------------------------------------------------

sub test_asString : Test(1) {
    my $self = shift;

    my $cok = Quiq::Http::Cookie->new(sid=>4711,expires=>0);
    my $str = $cok->asString;
    $self->is($str,'sid=4711; expires=Thu, 01-Jan-1970 00:00:01 GMT');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Http::Cookie::Test->runTests;

# eof
