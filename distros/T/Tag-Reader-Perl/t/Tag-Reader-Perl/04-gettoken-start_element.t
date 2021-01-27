use strict;
use warnings;

use File::Object;
use Tag::Reader::Perl;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('start_element1.sgml')->s);
my @tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<element>',
		'element',
		1,
		1,
	],
	'Parsing of start element.',
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('start_element2.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<element:color>',
		'element:color',
		1,
		1,
	],
	'Parsing of start element with prefix.',
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('start_element3.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<element attr="param">',
		'element',
		1,
		1,
	],
	'Parsing of start element with attribute.',
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('start_element4.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<element attr="param" />',
		'element',
		1,
		1,
	],
	'Parsing of simple element with attribute.',
);
