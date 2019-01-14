#!/usr/bin/env perl

package Quiq::Option::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Option');
}

# -----------------------------------------------------------------------------

sub test_extract_dontExtract : Test(3) {
    my $self = shift;

    my $argA = [qw/--log-level=2 --verbose a b c/];
    my $opt = Quiq::Option->extract(-dontExtract=>1,$argA,
        -logLevel=>1,
        -verbose=>0,
    );
    $self->is($opt->{'logLevel'},2);
    $self->is($opt->{'verbose'},1);
    $self->isDeeply($argA,[qw/--log-level=2 --verbose a b c/]);
}

sub test_extract : Test(21) {
    my $self = shift;

    my @arr = (
        [qw/--log-level=2 --verbose a b c/],
        [qw/a --log-level=2 b --verbose c/],
        [qw/-log-level 2 -verbose 1 a b c/],
        [qw/a -log-level 2 b -verbose 1 c/],
        [qw/--log-level=2 -verbose 1 a b c/],
        [qw/-log-level 2 --verbose a b c/],
        [qw/-logLevel 2 -verbose 1 a b c/],
    );

    for my $argA (@arr) {
        my $opt = Quiq::Option->extract($argA,
            -logLevel=>1,
            -verbose=>0,
        );
        $self->is($opt->{'logLevel'},2);
        $self->is($opt->{'verbose'},1);
        $self->isDeeply($argA,[qw/a b c/]);
    }
}

sub test_extract_varMode : Test(21) {
    my $self = shift;

    my @arr = (
        [qw/--log-level=2 --verbose a b c/],
        [qw/a --log-level=2 b --verbose c/],
        [qw/-log-level 2 -verbose 1 a b c/],
        [qw/a -log-level 2 b -verbose 1 c/],
        [qw/--log-level=2 -verbose 1 a b c/],
        [qw/-log-level 2 --verbose a b c/],
        [qw/-logLevel 2 -verbose 1 a b c/],
    );

    for my $argA (@arr) {
        my $logLevel = 1;
        my $verbose = 0;

        Quiq::Option->extract($argA,
            -logLevel=>\$logLevel,
            -verbose=>\$verbose,
        );
        $self->is($logLevel,2);
        $self->is($verbose,1);
        $self->isDeeply($argA,[qw/a b c/]);
    }
}

sub test_extract_help : Test(1) {
    my $self = shift;

    # Option -h

    my $argA = ['-h'];

    my $help = 0;
    Quiq::Option->extract($argA,
        -help=>\$help,
    );
    $self->is($help,1);
}

sub test_extract_properties : Test(3) {
    my $self = shift;

    my $argA = [a=>4,b=>5,c=>6];

    my $a = 1;
    my $b = 2;
    my $c = 3;

    Quiq::Option->extract(-properties=>1,$argA,
        a=>\$a,
        b=>\$b,
        c=>\$c,
    );
    $self->is($a,4);
    $self->is($b,5);
    $self->is($c,6);
}

# -----------------------------------------------------------------------------

sub test_extractAll : Test(2) {
    my $self = shift;

    my @arr = ('a','b','c',-d=>1,'e',-f=>2,'g');
    my @opt = Quiq::Option->extractAll(\@arr);
    $self->isDeeply(\@opt,[-d=>1,-f=>2]);
    $self->isDeeply(\@arr,[qw/a b c e g/]);
}

# -----------------------------------------------------------------------------

sub test_extractMulti_1 : Test(2) {
    my $self = shift;

    my @arr;
    my @select;
    my $limit;

    Quiq::Option->extractMulti(\@arr,
        -select=>\@select,
        -limit=>$limit,
    );

    $self->isDeeply(\@select,[]);
    $self->is($limit,undef);
}

sub test_extractMulti_2 : Test(2) {
    my $self = shift;

    my @arr = (-select=>'*',-limit=>0);
    my @select;
    my $limit;

    Quiq::Option->extractMulti(\@arr,
        -select=>\@select,
        -limit=>\$limit,
    );

    $self->isDeeply(\@select,['*']);
    $self->is($limit,0);
}

sub test_extractMulti_3 : Test(2) {
    my $self = shift;

    my @arr = (-select=>'a','b','c',-limit=>0,-select=>'d',-limit=>1);
    my @select;
    my $limit;

    Quiq::Option->extractMulti(\@arr,
        -select=>\@select,
        -limit=>\$limit,
    );

    $self->isDeeply(\@select,[qw/a b c d/]);
    $self->is($limit,1);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Option::Test->runTests;

# eof
