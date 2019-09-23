#!/usr/bin/env perl

package Quiq::Parameters::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Parameters');
}

# -----------------------------------------------------------------------------

sub test_extract_varMode_on : Test(4) {
    my $self = shift;

    my $logLevel = 1;
    my $verbose = 0;

    my @params = qw/--log-level=2 --verbose --remove a b c/;
    my $argA = Quiq::Parameters->extract(1,0,undef,\@params,2,
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
    my ($argA,$opt) = Quiq::Parameters->extract(0,0,undef,\@params,2,
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
Quiq::Parameters::Test->runTests;

# eof
