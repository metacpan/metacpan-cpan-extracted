#!perl

use strict;
use warnings;

use Test::More tests => 11;
use Test::Regexp::Pattern;

use Regexp::Pattern;

use Test::Requires { 're::engine::RE2' => 0 };

my $re = re( 'License::beerware', engine => 'RE2', subject => 'name' );

isa_ok( $re, 're::engine::RE2' );
like( "$re", qr/\Q|(?:[Tt]he )?\bBeerware\b|/ );

regexp_patterns_in_module_ok(
	'Regexp::Pattern::License',
	{ engine => 'RE2' }, 'using RE2'
);

regexp_patterns_in_module_ok(
	'Regexp::Pattern::License::Parts',
	{ engine => 'RE2' }, 'parts using RE2'
);

# subject
regexp_patterns_in_module_ok(
	'Regexp::Pattern::License',
	{ engine => 'RE2', subject => 'name' },
	'using RE2 with subject name'
);
regexp_patterns_in_module_ok(
	'Regexp::Pattern::License',
	{ engine => 'RE2', subject => 'grant' },
	'using RE2 with subject grant'
);
regexp_patterns_in_module_ok(
	'Regexp::Pattern::License',
	{ engine => 'RE2', subject => 'license' },
	'using RE2 with subject license'
);
regexp_patterns_in_module_ok(
	'Regexp::Pattern::License',
	{ engine => 'RE2', subject => 'iri' },
	'using RE2 with subject iri'
);

# capture
regexp_patterns_in_module_ok(
	'Regexp::Pattern::License',
	{ engine => 'RE2', capture => 'named' },
	'using RE2 with named capture'
);
regexp_patterns_in_module_ok(
	'Regexp::Pattern::License',
	{ engine => 'RE2', capture => 'numbered' },
	'using RE2 with numbered capture'
);
regexp_patterns_in_module_ok(
	'Regexp::Pattern::License',
	{ engine => 'RE2', capture => 'no' },
	'using RE2 without capture'
);
