#!/usr/bin/env perl

package Quiq::Test::Class::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Test::Class');
}

# -----------------------------------------------------------------------------

sub test_fixtureDir : Test(0) {
    my $self = shift;

    # my $dir = $self->fixtureDir;
    # like $dir,qr|t/R1::Misc/Test/Class/fixture$|,"Fixture-Verzeichnis ($dir)";
}

# -----------------------------------------------------------------------------

sub test_testDir : Test(0) {
    my $self = shift;

    # my $dir = $self->testDir;
    # like $dir,qr|t/R1::Misc/Test/Class$|,"Testverzeichnis ($dir)";
}

# -----------------------------------------------------------------------------

package main;
Quiq::Test::Class::Test->runTests;

# eof
