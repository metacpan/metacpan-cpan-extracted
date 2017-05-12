#!/usr/bin/perl

##
## Tests for Pangloss::Category
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Error qw( :try );
use Test::More 'no_plan';

use StoredObjectCommonTests;

BEGIN { use_ok("Pangloss::Category") }
BEGIN { use_ok("Pangloss::Categories"); }
BEGIN { use_ok("Pangloss::Category::Error"); }

##
## test single category
##

my $cat = new Pangloss::Category;
ok( $cat, 'new' ) || die "cannot proceed\n";

StoredObjectCommonTests->test( $cat );

try { is( $cat->validate, $cat, 'validate' ); }
catch Error with { fail(shift); };

{
    my $e;
    try { Pangloss::Category->new->validate; }
    catch Error with { $e = shift; };

    if (isa_ok( $e, 'Pangloss::Category::Error', 'validate error' )) {
	isa_ok( $e->category, 'Pangloss::Category', 'error->category' );
	ok    ( $e->isInvalid,                      'error->isInvalid' );
	ok    ( $e->isNameRequired,                 'error->isNameRequired' );
	ok    ( $e->isDateRequired,                 'error->isDateRequired' );
	ok    ( $e->isCreatorRequired,              'error->isCreatorRequired' );
    }
}


##
## test collection of categories
##

my $cats = new Pangloss::Categories();
ok( $cats, 'new categories' ) || die "cannot proceed\n";

is( scalar @{ $cats->names }, 0, 'names' );

is( $cats->get_values_key( $cat ), $cat->name, 'get_values_key' );

{
    my $e;
    try { $cats->get( $cat->name ); } catch Error with { $e = shift };
    if (isa_ok( $e, 'Pangloss::Category::Error', 'get non-existent' )) {
	ok( $e->isNonExistent, 'error->isNonExistent' );
    }
}

{
    my $e;
    try { $cats->add( $cat )->add( $cat ); } catch Error with { $e = shift };
    if (isa_ok( $e, 'Pangloss::Category::Error', 'add existing' )) {
	ok( $e->isExists, 'error->isExists' );
    }
}

