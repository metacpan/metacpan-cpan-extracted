# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use Tag::Reader::Perl;
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('dtd-element1.sgml')->s);
my @tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!ELEMENT br EMPTY>',
		'!element',
		1,
		1,
	],
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('dtd-element2.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!ELEMENT p (#PCDATA|emph)* >',
		'!element',
		1,
		1,
	],
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('dtd-element3.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!ELEMENT %name.para; %content.para; >',
		'!element',
		1,
		1,
	],
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('dtd-element4.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!ELEMENT container ANY>',
		'!element',
		1,
		1,
	],
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('dtd-element5.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!ELEMENT spec (front, body, back?)>',
		'!element',
		1,
		1,
	],
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('dtd-element6.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!ELEMENT div1 (head, (p | list | note)*, div2)>',
		'!element',
		1,
		1,
	],
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('dtd-element7.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!ELEMENT dictionary-body (%div.mix; | %dict.mix;)*>',
		'!element',
		1,
		1,
	],
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('dtd-element8.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!ELEMENT p (#PCDATA|a|ul|b|i|em)*>',
		'!element',
		1,
		1,
	],
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('dtd-element9.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!ELEMENT p (#PCDATA | %font; | %phrase; | %special; '.
			'| %form;)* >',
		'!element',
		1,
		1,
	],
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('dtd-element10.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!ELEMENT b (#PCDATA)>',
		'!element',
		1,
		1,
	],
);
