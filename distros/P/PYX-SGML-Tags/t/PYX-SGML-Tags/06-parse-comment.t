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
$obj->parse('_comment');
is($tags->flush, '<!--comment-->', 'Simple comment.');
$tags->reset;

# Test.
$obj->parse('_comment\ncomment');
is($tags->flush, "<!--comment\ncomment-->", 'Two coments with newline.');
$tags->reset;
