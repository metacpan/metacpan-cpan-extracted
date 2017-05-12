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
$obj->set_file($data_dir->file('conditional1.sgml')->s);
my @tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<![%foo[<!ELEMENT foo EMPTY>]]>',
		'![%foo[',
		1,
		1,
	],
	'Parse conditional #1.',
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('conditional2.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<![ %foo [<!ELEMENT foo EMPTY>]]>',
		'![',
		1,
		1,
	],
	'Parse conditional #2.',
);
