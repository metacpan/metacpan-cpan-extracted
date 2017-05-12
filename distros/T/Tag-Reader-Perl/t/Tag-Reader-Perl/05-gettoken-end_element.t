# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use Tag::Reader::Perl;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('end_element1.sgml')->s);
my @tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</element>',
		'/element',
		1,
		1,
	],
	'Parsing of end of element.',
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('end_element2.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</element:color>',
		'/element:color',
		1,
		1,
	],
	'Parsing of prefixed end of element.',
);
