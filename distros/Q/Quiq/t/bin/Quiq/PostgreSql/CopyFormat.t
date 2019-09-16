#!/usr/bin/env perl

package Quiq::PostgreSql::CopyFormat::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::PostgreSql::CopyFormat');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(3) {
    my $self = shift;

    my $cpy = Quiq::PostgreSql::CopyFormat->new(2);
    $self->is(ref($cpy),'Quiq::PostgreSql::CopyFormat');

    my $line = $cpy->arrayToLine([3,"Dies\tist ein\nTest"]);
    $self->is($line,"3\tDies\\tist ein\\nTest");

    eval {$cpy->arrayToLine([5])};
    $self->ok($@);
}

# -----------------------------------------------------------------------------

package main;
Quiq::PostgreSql::CopyFormat::Test->runTests;

# eof
