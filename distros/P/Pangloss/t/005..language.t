#!/usr/bin/perl

##
## Tests for Pangloss::Language & Pangloss::Languages
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Error qw( :try );
use Test::More 'no_plan';

use StoredObjectCommonTests;

BEGIN { use_ok("Pangloss::Language", qw( dir_LTR dir_RTL )) }
BEGIN { use_ok("Pangloss::Languages"); }
BEGIN { use_ok("Pangloss::Language::Error"); }

##
## test single language
##

my $lang = new Pangloss::Language;
isa_ok( $lang, 'Pangloss::Language', 'new' ) || die("cannot proceed\n");

is( $lang->iso_code(2), $lang, 'iso_code(set)' );
is( $lang->iso_code, 2,        'iso_code(get)' );

is( $lang->direction(dir_RTL), $lang, 'direction(set)' );
is( $lang->direction, dir_RTL,        'direction(get)' );

ok( $lang->is_rtl, 'is_rtl' );
$lang->direction(dir_LTR);
ok( $lang->is_ltr, 'is_ltr' );

StoredObjectCommonTests->test( $lang );

try { is( $lang->validate, $lang, 'validate' ); }
catch Error with { fail(shift); };

{
    my $e;
    try { Pangloss::Language->new->validate; }
    catch Error with { $e = shift; };

    if (isa_ok( $e, 'Pangloss::Language::Error', 'validate error' )) {
	isa_ok( $e->language, 'Pangloss::Language', 'error->language' );
	ok    ( $e->isInvalid,                      'error->flag' );
	ok    ( $e->isNameRequired,                 'error->isNameRequired' );
	ok    ( $e->isDateRequired,                 'error->isDateRequired' );
	ok    ( $e->isCreatorRequired,              'error->isCreatorRequired' );
	ok    ( $e->isIsoCodeRequired,              'error->isIsoCodeRequired' );
	ok    ( $e->isDirectionRequired,            'error->isDirectionRequired' );
    }
}

##
## test collection of languages
##

my $langs = new Pangloss::Languages();
isa_ok( $langs, 'Pangloss::Languages', 'new languages' ) || die("cannot proceed\n");

is( scalar @{ $langs->iso_codes },  0, 'iso_codes' );

is( $langs->get_values_key( $lang ), $lang->iso_code, 'get_values_key' );

{
    my $e;
    try { $langs->get( $lang->iso_code ); } catch Error with { $e = shift };
    if (isa_ok( $e, 'Pangloss::Language::Error', 'get non-existent' )) {
	ok( $e->isNonExistent, 'error->isNonExistent' );
    }
}

{
    my $e;
    try { $langs->add( $lang )->add( $lang ); } catch Error with { $e = shift };
    if (isa_ok( $e, 'Pangloss::Language::Error', 'add existing' )) {
	ok( $e->isExists, 'error->isExists' );
    }
}

