# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::Raw;
use Test::More 'tests' => 2;
use Test::NoWarnings;

my $obj = Tags::Output::Raw->new(
	'no_simple' => ['element'],
	'xml' => 1,
);
$obj->put(
	['b', 'element'],
	['e', 'element'],
);
my $ret = $obj->flush;
my $right_ret = '<element></element>';
is($ret, $right_ret);
