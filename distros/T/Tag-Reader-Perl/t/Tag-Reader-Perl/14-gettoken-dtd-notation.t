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
$obj->set_file($data_dir->file('dtd-notation1.sgml')->s);
my @tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<!NOTATION USDATE SYSTEM ".
			"\"http://www.schema.net/usdate.not\">",
		'!notation',
		1,
		1,
	],
	'Parse notation #1.',
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('dtd-notation2.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<!NOTATION GIF\n".
			"           PUBLIC \"-//IETF/NOSGML Media ".
			"Type image/gif//EN\"\n".
			"           \"http://www.bug.com/image/gif\">",
		'!notation',
		1,
		1,
	],
	'Parse notation #2.',
);
