# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::Indent;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Indent->new;
$obj->put(
	['b', 'element'],
);
$obj->finalize;
my $ret = $obj->flush;
is($ret, '<element>', 'Finalize open element in SGML mode.');

# Test.
$obj = Tags::Output::Indent->new(
	'xml' => 1,
);
$obj->put(
	['b', 'element'],
);
$obj->finalize;
$ret = $obj->flush;
is($ret, '<element />', 'Finalize open element in XML mode.');
