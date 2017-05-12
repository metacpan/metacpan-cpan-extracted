#!/usr/bin/perl

use strict;
use warnings;

use RTF::Parser;
use Test::More tests => 2;

my $object = RTF::Parser->new();

ok( !( $object->control_definition ), "No control definitions installed yet" );

my $cds = {

    b    => sub { return 'la' },
    ansi => sub { return 'ta' },

};

$object->control_definition($cds);

ok( eq_hash( ( $object->control_definition ), $cds ),
    "Control definitions returned correctly" );

