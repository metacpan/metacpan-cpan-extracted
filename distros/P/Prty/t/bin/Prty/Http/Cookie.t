#!/usr/bin/env perl

package Prty::Http::Cookie::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Http::Cookie');
}

# -----------------------------------------------------------------------------

sub test_new : Test(2) {
    my $self = shift;

    my $cok = Prty::Http::Cookie->new(sid=>4711);

    my $name = $cok->get('name');
    $self->is($name,'sid');

    my $value = $cok->get('value');
    $self->is($value,4711);
}

# -----------------------------------------------------------------------------

sub test_asString : Test(1) {
    my $self = shift;

    my $cok = Prty::Http::Cookie->new(sid=>4711,expires=>0);
    my $str = $cok->asString;
    $self->is($str,'sid=4711; expires=Thu, 01-Jan-1970 00:00:01 GMT');
}

# -----------------------------------------------------------------------------

package main;
Prty::Http::Cookie::Test->runTests;

# eof
