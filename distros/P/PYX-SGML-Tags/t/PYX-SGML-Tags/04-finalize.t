use strict;
use warnings;

use PYX::SGML::Tags;
use Tags::Output::Raw;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Raw->new(
	'xml' => 1,
);
my $obj = PYX::SGML::Tags->new(
	'tags' => $tags,
);
$obj->parse('(element');
my $ret = $obj->finalize;
is($ret, undef, 'Finalize.');
$ret = $tags->flush;
is($ret, '<element />', 'Closed element by finalize.');
