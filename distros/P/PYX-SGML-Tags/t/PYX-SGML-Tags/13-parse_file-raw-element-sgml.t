use strict;
use warnings;

use File::Object;
use PYX::SGML::Tags;
use Tags::Output::Raw;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $tags = Tags::Output::Raw->new;
my $obj = PYX::SGML::Tags->new(
	'tags' => $tags,
);
$obj->parse_file($data_dir->file('element1.pyx')->s);
is($tags->flush, "<element></element>", 'Simple element (sgml version).');
$tags->reset;

# Test.
$obj->parse_file($data_dir->file('element2.pyx')->s);
is($tags->flush, "<element par=\"val\"></element>",
	'Simple element with attribute (sgml version).');
$tags->reset;

# Test.
$obj->parse_file($data_dir->file('element3.pyx')->s);
is($tags->flush, "<element par=\"val\\nval\"></element>",
	'Simple element with attribute with \n in value (sgml version).');
$tags->reset;

# Test.
$obj->parse_file($data_dir->file('element4.pyx')->s);
is($tags->flush, decode_utf8('<čupřina cíl="ředkev"></čupřina>'),
	'Parse element with attribute in utf-8 (sgml version).');
$tags->reset;
