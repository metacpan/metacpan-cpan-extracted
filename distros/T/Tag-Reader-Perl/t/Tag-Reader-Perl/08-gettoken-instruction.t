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
$obj->set_file($data_dir->file('instruction1.sgml')->s);
my @tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<?xml?>',
		'?xml',
		1,
		1,
	],
	'Parse bad XML declaration.',
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('instruction2.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<?xml version="1.0"?>',
		'?xml',
		1,
		1,
	],
	'Parse valid XML declaration.',
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('instruction3.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<?application This is normal sentence.\nAnd second sentence.?>",
		'?application',
		1,
		1,

	],
	'Parse instruction with newline in code.',
);
