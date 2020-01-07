#!perl

use strict;
use warnings;

use Test::More tests => 11;
use Test::Regexp::Pattern;

use Regexp::Pattern;

my $re = re( 'License::beerware', subject => 'name' );

# TODO: use embedded examples instead, when figuring out how...
isa_ok( $re, 'Regexp' );
is( "$re", '(?^:$the?[Bb]eer$D?ware(?: License)?)' );

regexp_patterns_in_module_ok('Regexp::Pattern::License');

regexp_patterns_in_module_ok( 'Regexp::Pattern::License::Parts', 'parts' );

# subject
regexp_patterns_in_module_ok(
	'Regexp::Pattern::License',
	{ subject => 'name' }, 'with subject name'
);
regexp_patterns_in_module_ok(
	'Regexp::Pattern::License',
	{ subject => 'grant' }, 'with subject grant'
);
regexp_patterns_in_module_ok(
	'Regexp::Pattern::License',
	{ subject => 'license' }, 'with subject license'
);
regexp_patterns_in_module_ok(
	'Regexp::Pattern::License',
	{ subject => 'iri' }, 'with subject iri'
);

# capture
regexp_patterns_in_module_ok(
	'Regexp::Pattern::License',
	{ capture => 'named' }, 'with named capture'
);
regexp_patterns_in_module_ok(
	'Regexp::Pattern::License',
	{ capture => 'numbered' }, 'with numbered capture'
);
regexp_patterns_in_module_ok(
	'Regexp::Pattern::License',
	{ capture => 'no' }, 'without capture'
);
