#!/usr/bin/env perl

package Quiq::Hash::Persistent::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Hash::Persistent');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(7) {
    my $self = shift;

    my $p = Quiq::Path->new;

    my $file = $p->tempFile(-pathOnly=>1);
    my $timeout = 5;

    my $h = Quiq::Hash::Persistent->new("$file",$timeout,sub {
        my $class = shift;
        return $class->Quiq::Hash::new(
            a => 1,
            b => 2,
        );
    });

    $self->is(ref($h),'Quiq::Hash::Persistent');
    $self->is($h->a,1);
    $self->is($h->b,2);
    $self->is($h->cacheFile,$file);
    $self->is($h->cacheTimeout,$timeout);

    # Geänderte Werte

    $h = Quiq::Hash::Persistent->new("$file",$timeout,sub {
        my $class = shift;
        return $class->Quiq::Hash::new(
            a => 3,
            b => 4,
        );
    });

    # ...aber wir lesen immernoch dasselbe aus dem Cache

    $self->is($h->a,1);
    $self->is($h->b,2);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Hash::Persistent::Test->runTests;

# eof
