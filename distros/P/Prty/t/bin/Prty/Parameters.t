#!/usr/bin/env perl

package Prty::Parameters::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Parameters');
}

# -----------------------------------------------------------------------------

sub test_extract_varMode_on : Test(4) {
    my $self = shift;

    my $logLevel = 1;
    my $verbose = 0;

    my @params = qw/--log-level=2 --verbose --remove a b c/;
    my $argA = Prty::Parameters->extract(1,undef,\@params,2,
        -logLevel => \$logLevel,
        -verbose => \$verbose,
    );
    $self->is($logLevel,2);
    $self->is($verbose,1);
    $self->isDeeply($argA,[qw/a b/]);
    $self->isDeeply(\@params,['--remove','c']);
}

sub test_extract_varMode_off : Test(4) {
    my $self = shift;

    my @params = qw/--log-level=2 --verbose --remove a b c/;
    my ($argA,$opt) = Prty::Parameters->extract(0,undef,\@params,2,
        -logLevel => 1,
        -verbose => 0,
    );
    $self->is($opt->logLevel,2);
    $self->is($opt->verbose,1);
    $self->isDeeply($argA,[qw/a b/]);
    $self->isDeeply(\@params,['--remove','c']);
}

# -----------------------------------------------------------------------------

package main;
Prty::Parameters::Test->runTests;

# eof
