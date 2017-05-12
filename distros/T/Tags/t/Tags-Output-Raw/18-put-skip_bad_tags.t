# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::Raw;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Raw->new(
	'skip_bad_tags' => 1,
);
$obj->put(
	['b', 'element'],
	['q', 'element'],
	['e', 'element'],
);
$obj->finalize;
my $ret = $obj->flush;
is($ret, '<element></element>');
