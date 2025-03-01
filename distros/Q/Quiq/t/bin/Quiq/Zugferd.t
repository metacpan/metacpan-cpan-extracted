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

sub test_unitTest: Test(6) {
    my $self = shift;

    if ($0 =~ /\.cotedo/) {
        $ENV{'ZUGFERD_DIR'} = $ENV{'HOME'}.'/dvl/jaz/Blob/zugferd/profile/'.
            'en16931';
    }

    my $xml = Quiq::Zugferd->createTemplate('minimum');
    $self->like($xml,qr/<rsm:SupplyChainTradeTransaction>/);

    $xml = Quiq::Zugferd->createTemplate('basicwl');
    $self->like($xml,qr/<rsm:SupplyChainTradeTransaction>/);

    $xml = Quiq::Zugferd->createTemplate('basic');
    $self->like($xml,qr/<rsm:SupplyChainTradeTransaction>/);

    $xml = Quiq::Zugferd->createTemplate('en16931');
    $self->like($xml,qr/<rsm:SupplyChainTradeTransaction>/);

    $xml = Quiq::Zugferd->createTemplate('extended');
    $self->like($xml,qr/<rsm:SupplyChainTradeTransaction>/);

    my $zug = Quiq::Zugferd->new('en16931');
    $self->is(ref($zug),'Quiq::Zugferd');

    # FIXME: Tests hinzufügen

    my $str = $zug->doc('xml');
    $str = $zug->doc('tree');

    $xml = $zug->xml('empty');
    $xml = $zug->xml('placeholders');
    $xml = $zug->xml('values');

    my $tree = $zug->tree('empty'); # Kann nicht nach XML gewandelt werden
    $tree = $zug->tree('placeholders'); # Kann nicht nach XML gewandelt werden
    $tree = $zug->tree('values');

    $xml = $zug->treeToXml($tree,-validate=>0);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Zugferd::Test->runTests;

# eof
