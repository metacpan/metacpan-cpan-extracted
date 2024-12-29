#!/usr/bin/env perl

package Quiq::Zugferd::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Zugferd');
}

# -----------------------------------------------------------------------------

sub test_unitTest: Test(1) {
    my $self = shift;

    my $zug = Quiq::Zugferd->new;
    $self->is(ref($zug),'Quiq::Zugferd');

    # FIXME: Tests hinzufügen

    my $str = $zug->doc('xml');
    $str = $zug->doc('hash');

    my $xml = $zug->xml('empty');
    $xml = $zug->xml('placeholders');
    $xml = $zug->xml('values');

    my $h = $zug->hash('empty'); # Kann nicht nach XML gewandelt werden
    $h = $zug->hash('placeholders'); # Kann nicht nach XML gewandelt werden
    $h = $zug->hash('values');
    $xml = $zug->hashToXml($h);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Zugferd::Test->runTests;

# eof
