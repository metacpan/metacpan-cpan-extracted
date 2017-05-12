#!/usr/bin/perl

##
## Tests for Pangloss::User & Pangloss::Users
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Error qw( :try );
use Test::More 'no_plan';

use StoredObjectCommonTests;

use Pangloss::Language;
BEGIN { use_ok("Pangloss::User"); }
BEGIN { use_ok("Pangloss::Users"); }
BEGIN { use_ok("Pangloss::User::Error"); }

##
## test single user
##
my $user = new Pangloss::User;
isa_ok( $user, 'Pangloss::User', 'new user' ) || die("cannot proceed\n");

is( $user->id( 'test' ), $user, 'id(set)' );
is( $user->id, 'test',          'id(get)' );

isa_ok( $user->privileges, 'Pangloss::User::Privileges', 'privileges(get)' );

StoredObjectCommonTests->test( $user );

try { is( $user->validate, $user, 'validate' ); }
catch Error with { fail(shift); };

{
    my $e;
    try { Pangloss::User->new->validate; }
    catch Error with { $e = shift; };

    if (isa_ok( $e, 'Pangloss::User::Error', 'validate error' )) {
	isa_ok( $e->user, 'Pangloss::User', 'error->user' );
	ok    ( $e->isInvalid,              'error->isInvalid' );
	ok    ( $e->isIdRequired,           'error->isIdRequired' );
	ok    ( $e->isNameRequired,         'error->isNameRequired' );
	ok    ( $e->isDateRequired,         'error->isDateRequired' );
	ok    ( $e->isCreatorRequired,      'error->isCreatorRequired' );
    }
}


##
## test collection of users
##
my $users = new Pangloss::Users();
isa_ok( $users, 'Pangloss::Users', 'new users' ) || die("cannot proceed\n");

is( scalar @{ $users->ids },  0, 'ids' );

is( $users->get_values_key( $user ), $user->id, 'get_values_key' );

{
    my $e;
    try { $users->get( $user->id ); }
    catch Error with { $e = shift };
    if (isa_ok( $e, 'Pangloss::User::Error', 'get non-existent' )) {
	ok( $e->isNonExistent, 'error->isNonExistent' );
    }
}

{
    my $e;
    try { $users->add( $user )->add( $user ); }
    catch Error with { $e = shift };
    if (isa_ok( $e, 'Pangloss::User::Error', 'add existing' )) {
	ok( $e->isExists, 'error->isExists' );
    }
}


##
## test privileges shortcuts
##
my $lang  = new Pangloss::Language()->name('test')->iso_code('t');
$user     = new Pangloss::User();
$user->privileges->admin(1);
ok( $user->is_admin,               'is_admin' );
ok( $user->is_translator,          'is_translator' );
ok( $user->can_translate( $lang ), 'can_translate(lang)' );
ok( $user->is_proofreader,         'is_proofreader' );
ok( $user->can_proofread( $lang ), 'can_proofread(lang)' );
ok( $user->can_add_concepts,       'can_add_concepts' );
ok( $user->can_add_categories,     'can_add_categories' );

$user->privileges->admin(0);
ok( $user->not_admin,               'not_admin' );
ok( $user->not_translator,          'not_translator' );
ok( $user->cant_translate( $lang ), 'cant_translate(lang)' );
ok( $user->not_proofreader,         'not_proofreader()' );
ok( $user->cant_proofread( $lang ), 'cant_proofread(lang)' );
ok( $user->cant_add_concepts,       'can_add_concepts' );
ok( $user->cant_add_categories,     'can_add_categories' );

$user->privileges->add_translate_languages( $lang );
ok( $user->is_translator, 'is_translator()' );

$user->privileges->add_proofread_languages( $lang );
ok( $user->is_proofreader, 'is_proofreader()' );

$user->privileges->add_concepts(1);
ok( $user->can_add_concepts, 'can_add_concepts' );

$user->privileges->add_categories(1);
ok( $user->can_add_categories, 'can_add_categories' );

$user->privileges->add_translate_languages($lang);
ok(  $user->can_translate( $lang ),  'can_translate(lang)' );
ok(! $user->cant_translate( $lang ), 'cant_translate(lang)' );

$user->privileges->add_proofread_languages($lang);
ok(  $user->can_proofread( $lang ),  'can_proofread(lang)' );
ok(! $user->cant_proofread( $lang ), 'cant_proofread(lang)' );

