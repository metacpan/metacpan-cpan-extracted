#!/usr/bin/perl

##
## Tests for Pangloss::Concept
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Error qw( :try );
use Test::More 'no_plan';

use StoredObjectCommonTests;

BEGIN { use_ok("Pangloss::Concept") }
BEGIN { use_ok("Pangloss::Concepts") }
BEGIN { use_ok("Pangloss::Concept::Error") }

##
## test single concept
##

my $concept = new Pangloss::Concept;
ok( $concept, 'new' ) || die "cannot continue\n";

is( $concept->category(1), $concept, 'category(set)' );
is( $concept->category, 1,           'category(get)' );

StoredObjectCommonTests->test( $concept );

try { is( $concept->validate, $concept, 'validate' ); }
catch Error with { fail(shift); };

{
    my $e;
    try { Pangloss::Concept->new->validate; }
    catch Error with { $e = shift; };

    if (isa_ok( $e, 'Pangloss::Concept::Error', 'validate error' )) {
	isa_ok( $e->concept, 'Pangloss::Concept', 'error->concept' );
	ok    ( $e->isInvalid,                    'error->isInvalid' );
	ok    ( $e->isNameRequired,               'error->isNameRequired' );
	ok    ( $e->isDateRequired,               'error->isDateRequired' );
	ok    ( $e->isCreatorRequired,            'error->isCreatorRequired' );
    } else {
	diag( $e );
    }
}


##
## test collection of concepts
##

my $concepts = new Pangloss::Concepts();
ok( $concepts, 'new concepts' ) || die "cannot proceed\n";

is( scalar @{ $concepts->names }, 0, 'names' );

is( $concepts->get_values_key( $concept ), $concept->name, 'get_values_key' );

{
    my $e;
    try { $concepts->get( $concept->name ); } catch Error with { $e = shift };
    if (isa_ok( $e, 'Pangloss::Concept::Error', 'get non-existent' )) {
	ok( $e->isNonExistent, 'error->isNonExistent' );
    }
}

{
    my $e;
    try { $concepts->add( $concept )->add( $concept ); } catch Error with { $e = shift };
    if (isa_ok( $e, 'Pangloss::Concept::Error', 'add existing' )) {
	ok( $e->isExists, 'error->isExists' );
    }
}

