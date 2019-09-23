#!/usr/bin/env perl

package Quiq::ClassConfig::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Perl;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ClassConfig');
}

# -----------------------------------------------------------------------------

sub test_unitTest_root: Test(7) {
    my $self = shift;

    # BaseClass
    #    |
    # SubClass1
    #    |
    # SubClass2

    my $baseClass = 'BaseClass';
    Quiq::Perl->createClass($baseClass,'Quiq::ClassConfig');
    $baseClass->def(
        name => 'B',
        columns => [qw/
            Id
        /],
    );

    my $subClass1 = 'SubClass1';
    Quiq::Perl->createClass($subClass1,$baseClass);
    $subClass1->def(
        name => 'S',
        columns => [qw/
            Name
        /],
    );

    my $subClass2 = 'SubClass2';
    Quiq::Perl->createClass($subClass2,$subClass1);

    # defGet

    my $name = $baseClass->defGet('name');
    $self->is($name,'B');

    $name = $subClass1->defGet('name');
    $self->is($name,'S');

    $name = $subClass2->defGet('name');
    $self->is($name,undef);

    # defSearch

    $name = $subClass2->defSearch('name');
    $self->is($name,'S');

    # defCumulate
    
    my @arr = $baseClass->defCumulate('columns');
    $self->isDeeply(\@arr,[qw/Id/]);

    @arr = $subClass1->defCumulate('columns');
    $self->isDeeply(\@arr,[qw/Id Name/]);

    @arr = $subClass2->defCumulate('columns');
    $self->isDeeply(\@arr,[qw/Id Name/]);
}

# -----------------------------------------------------------------------------

package main;
Quiq::ClassConfig::Test->runTests;

# eof
