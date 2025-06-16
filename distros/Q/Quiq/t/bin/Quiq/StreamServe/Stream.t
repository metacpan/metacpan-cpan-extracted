#!/usr/bin/env perl

package Quiq::StreamServe::Stream::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Test::Class;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::StreamServe::Stream');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(6) {
    my $self = shift;

    my $streamFile = Quiq::Test::Class->testPath(
        'quiq/test/data/StreamServe/174582475500.str');

    my $ssf = Quiq::StreamServe::Stream->new($streamFile);
    $self->is(ref($ssf),'Quiq::StreamServe::Stream');

    my $val = $ssf->get('*JOBID');
    $self->is($val,'697601009531154959STS189PF');

    my $prefixA = $ssf->prefixes;
    $self->isDeeply($prefixA,[qw/* 0H 0I 0R 0S 0T 2H 2L TA VB/]);

    my $arrA = $ssf->blocks('*');
    $self->is(scalar(@$arrA),1);

    eval {$ssf->blocks('XX')};
    $self->ok($@);

    my $blockA = $ssf->allBlocks;
    $self->is(scalar(@$blockA),10);

    # Zeige die Struktur des Streams
    #
    # for my $prefix (sort keys %$ssf) {
    #     warn "$prefix:\n";
    #     my $i = 0;
    #     for my $h (@{$ssf->{$prefix}}) {
    #         warn "  $i:\n";
    #         for my $key (sort keys %$h) {
    #             warn "    $key = $h->{$key}\n";
    #         }
    #     }
    # }
}

# -----------------------------------------------------------------------------

package main;
Quiq::StreamServe::Stream::Test->runTests;

# eof
