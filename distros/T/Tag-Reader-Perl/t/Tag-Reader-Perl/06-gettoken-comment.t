# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use Tag::Reader::Perl;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('comment1.sgml')->s);
my @tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!-- comment -->',
		'!--',
		1,
		1,
	],
	'Parsing of comment.',
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('comment2.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!-- <element> text </element> -->',
		'!--',
		1,
		1,
	],
	'Parsing of comment with XML block.',
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('comment3.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!-- <<<< comment <> -->',
		'!--',
		1,
		1,
	],
	'Parsing of comment with some special characters.',
);
