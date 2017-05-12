#!/usr/bin/perl

##
## Tests for Pangloss::Term
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Error qw( :try );
use Test::More 'no_plan';

use StoredObjectCommonTests;

BEGIN { use_ok("Pangloss::Term") }
BEGIN { use_ok("Pangloss::Terms") }
BEGIN { use_ok("Pangloss::Term::Error") }

##
## test single term
##

my $term = new Pangloss::Term;
ok( $term, 'new' ) || die "cannot continue\n";

ok( $term->status, 'status(get)' );

is( $term->concept(2), $term, 'concept(set)' );
is( $term->concept, 2,        'concept(get)' );

is( $term->language(3), $term, 'language(set)' );
is( $term->language, 3,        'language(get)' );

StoredObjectCommonTests->test( $term );

try { is( $term->validate, $term, 'validate' ); }
catch Error with { fail(shift); };

{
    my $e;
    try { Pangloss::Term->new->status(undef)->validate; }
    catch Error with { $e = shift; };

    if (isa_ok( $e, 'Pangloss::Term::Error', 'validate error' )) {
	isa_ok( $e->term, 'Pangloss::Term',  'error->term' );
	ok    ( $e->isInvalid,               'error->isInvalid' );
	ok    ( $e->isNameRequired,          'error->isNameRequired' );
	ok    ( $e->isCreatorRequired,       'error->isCreatorRequired' );
	ok    ( $e->isDateRequired,          'error->isDateRequired' );
	ok    ( $e->isStatusRequired,        'error->isStatusRequired' );
	ok    ( $e->isConceptRequired,       'error->isConceptRequired' );
	ok    ( $e->isLanguageRequired,      'error->isLanguageRequired' );
    }
}


##
## test collection of terms
##

my $terms = new Pangloss::Terms();
ok( $terms, 'new terms' ) || die "cannot proceed\n";

is( scalar @{ $terms->names }, 0, 'names' );

is( $terms->get_values_key( $term ), $term->key, 'get_values_key' );

{
    my $e;
    try { $terms->get( $term->key ); } catch Error with { $e = shift };
    if (isa_ok( $e, 'Pangloss::Term::Error', 'get non-existent' )) {
	ok( $e->isNonExistent, 'error->isNonExistent' );
    }
}

{
    my $e;
    try { $terms->add( $term )->add( $term ); } catch Error with { $e = shift };
    if (isa_ok( $e, 'Pangloss::Term::Error', 'add existing' )) {
	ok( $e->isExists, 'error->isExists' );
    }
}

