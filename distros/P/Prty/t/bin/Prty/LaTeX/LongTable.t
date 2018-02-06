#!/usr/bin/env perl

package Prty::LaTeX::LongTable::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

use Prty::LaTeX::Generator;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::LaTeX::LongTable');
}

# -----------------------------------------------------------------------------

sub test_unitTest_0 : Test(2) {
    my $self = shift;

    my $tab = Prty::LaTeX::LongTable->new;
    $self->is(ref($tab),'Prty::LaTeX::LongTable');

    my $gen = Prty::LaTeX::Generator->new;
    my $code = $tab->latex($gen);
    $self->is($code,'');
}

# -----------------------------------------------------------------------------

sub test_unitTest_1 : Test(0) {
    my $self = shift;

    my $tab = Prty::LaTeX::LongTable->new(
        alignments => ['l','r','c'],
        titles => ['Links','Rechts','Zentriert'],
        rows => [
            ['A',1,'AB'],
            ['AB',2,'CD'],
            ['ABC',3,'EF'],
            ['ABCD',4,'GH'],
        ],            
    );

    my $gen = Prty::LaTeX::Generator->new;
    my $code = $tab->latex($gen);
    # warn "-----\n".$code."-----\n";
}

# -----------------------------------------------------------------------------

package main;
Prty::LaTeX::LongTable::Test->runTests;

# eof
