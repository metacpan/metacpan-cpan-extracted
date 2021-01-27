use strict;
use warnings;

use File::Object;
use Tag::Reader::Perl;
use Test::More 'tests' => 17;
use Test::NoWarnings;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('element1.sgml')->s);
my @tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<text>',
		'text',
		1,
		1,
	],
	'Simple XML - text element.',
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'text',
		'!data',
		1,
		7,
	],
	'Simple XML - data.',
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</text>',
		'/text',
		1,
		11,
	],
	'Simple XML - end of text element.',
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"\n",
		'!data',
		1,
		18,
	],
	'Simple XML - newline.',
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('element2.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<text:color>',
		'text:color',
		1,
		1,
	],
	'Prefixed XML - start element.',
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'text',
		'!data',
		1,
		13,
	],
	'Prefixed XML - data.',
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</text:color>',
		'/text:color',
		1,
		17,
	],
	'Prefixed XML - end of element.',
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"\n",
		'!data',
		1,
		30,
	],
	'Prefixed XML - newline.',
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('element3.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<text>',
		'text',
		1,
		1,
	],
	'XML with CDATA #1 - start element.',
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<![CDATA[<text>text</text>]]>',
		'![cdata[',
		1,
		7,
	],
	'XML with CDATA #1 - cdata.',
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</text>',
		'/text',
		1,
		36,
	],
	'XML with CDATA #1 - end of element.',
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"\n",
		'!data',
		1,
		43,
	],
	'XML with CDATA #1 - newline.',
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('element4.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<x>',
		'x',
		1,
		1,
	],
	'XML with CDATA #2 - start element.',
);
@tag = $obj->gettoken;
# TODO Co to je za typ?
is_deeply(
	\@tag,
	[
		'<![CDATA[a<x>b]]]>',
		'![cdata[a',
		1,
		4,
	],
	'XML with CDATA #2 - cdata.',
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</x>',
		'/x',
		1,
		22,
	],
	'XML with CDATA #2 - end of element.',
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"\n",
		'!data',
		1,
		26,
	],
	'XML with CDATA #2 - newline.',
);
