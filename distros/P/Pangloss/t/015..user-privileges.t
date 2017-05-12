#!/usr/bin/perl

##
## Tests for Pangloss::User::Privileges
##

use blib;
use strict;
use warnings;

use Error qw( :try );
use Test::More 'no_plan';

use Pangloss::Language;

BEGIN { use_ok("Pangloss::User::Privileges") }

my $privs = new Pangloss::User::Privileges;

isa_ok( $privs, 'Pangloss::User::Privileges', 'new' );

is( $privs->admin(1), $privs, 'admin(set)' );
is( $privs->admin, 1,         'admin(get)' );

is( $privs->add_concepts(1), $privs, 'add_concepts(set)' );
is( $privs->add_concepts, 1,         'add_concepts(get)' );

is( $privs->add_categories(1), $privs, 'add_categories(set)' );
is( $privs->add_categories, 1,         'add_categories(get)' );

isa_ok( $privs->translate_languages, 'HASH', 'translate_languages(get)' );
isa_ok( $privs->proofread_languages, 'HASH', 'proofread_languages(get)' );

my $lang = new Pangloss::Language()->name('test')->iso_code('t');
my $lang2 = new Pangloss::Language()->name('test 2')->iso_code('t2');

is( $privs->add_translate_languages($lang), $privs, 'add_translate_languages' );
ok( $privs->translate,                              'translate : yes' );
ok( $privs->can_translate($lang),                   'can_translate(lang) : yes' );
ok(! $privs->can_translate($lang2),                 'can_translate(lang2) : no ' );

is( $privs->add_proofread_languages($lang), $privs, 'add_proofread_languages' );
ok( $privs->proofread,                              'proofread : yes' );
ok( $privs->can_proofread($lang),                   'can_proofread(lang) : yes' );
ok(! $privs->can_proofread($lang2),                 'can_proofread(lang2) : no ' );

my $privs2 = $privs->new;
if (ok( $privs2->copy( $privs ), 'copy' )) {
    ok( $privs2->can_proofread($lang), 'copy proofread langs' );
    ok( $privs2->can_translate($lang), 'copy translate langs' );
    ok( $privs2->add_concepts(),       'copy add_concepts' );
    ok( $privs2->add_categories(),     'copy add_categories' );
    ok( $privs2->admin(),              'copy admin' );
}

ok( $privs->clone(), 'clone' );

is( $privs->remove_translate_languages($lang), $privs, 'remove_translate_languages' );
ok( ! $privs->can_translate($lang),                    'can_translate' );

is( $privs->remove_proofread_languages($lang), $privs, 'remove_proofread_languages' );
ok( ! $privs->can_proofread($lang),                    'can_proofread' );

TODO: {
    local $TODO = 'implement this';
    try { is( $privs->validate, $privs, 'validate' ); }
    catch Error with { my $e=shift; fail("$e"); };

    {
	my $e;
	try { Pangloss::Term::User::Privileges->new->validate; }
	catch Error with { $e = shift; };

	if (isa_ok( $e, 'Pangloss::User::Error', 'validate error' )) {
	    ; # ...
	}
    }
}

