# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::Structure;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Structure->new;
$obj->put(
	['i', 'perl'],
	['i', 'perl', 'print "1";'],
);
my $ret = $obj->flush;
is_deeply(
	$ret,
	[
		['i', 'perl'],
		['i', 'perl', 'print "1";'],
	],
	'Simple instruction test.',
);
