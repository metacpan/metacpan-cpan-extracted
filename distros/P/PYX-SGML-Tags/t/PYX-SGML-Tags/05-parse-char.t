use strict;
use warnings;

use PYX::SGML::Tags;
use Tags::Output::Raw;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Raw->new(
	'xml' => 1,
);
my $obj = PYX::SGML::Tags->new(
	'tags' => $tags,
);
$obj->parse('-char');
is($tags->flush, 'char', 'Simple data character.');
$tags->reset;

# Test.
$obj->parse('-char\nchar');
is($tags->flush, "char\nchar", 'Characters with newline between.');
$tags->reset;

# Test.
$obj->parse("-char\n-char");
is($tags->flush, "charchar", 'Two data characters.');
$tags->reset;
