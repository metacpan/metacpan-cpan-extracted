# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use Tag::Reader::Perl;
use Test::More 'tests' => 63;
use Test::NoWarnings;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('doc1.sgml')->s);
my @tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<?xml version=\"1.0\" encoding=\"UTF-8\" ".
			"standalone=\"yes\"?>",
		'?xml',
		1,
		1,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"\n",
		'!data',
		1,
		56,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<!DOCTYPE greeting [\n\t<!ELEMENT greeting (#PCDATA)>\n]>",
		'!doctype',
		2,
		1,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<greeting>',
		'greeting',
		5,
		1,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'Hello, world!',
		'!data',
		5,
		11,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</greeting>',
		'/greeting',
		5,
		24,
	],
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('doc2.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<?xml version=\"1.0\" standalone=\"yes\"?>",
		'?xml',
		1,
		1,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
my $right_ret = <<"END";
<!DOCTYPE image [
  <!ELEMENT image EMPTY>
  <!ATTLIST image
    height CDATA #REQUIRED
    width CDATA #REQUIRED>
]>
END
chomp $right_ret;
is_deeply(
	\@tag,
	[
		$right_ret,
		'!doctype',
		2,
		1,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<image height=\"32\" width=\"32\"/>",
		'image',
		8,
		1,
	],
);
$right_ret =~ s/^<!DOCTYPE image \[//;
$right_ret =~ s/\]>$//;
$obj->set_text($right_ret, 1);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!ELEMENT image EMPTY>',
		'!element',
		2,
		3,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
$right_ret = <<"END";
<!ATTLIST image
    height CDATA #REQUIRED
    width CDATA #REQUIRED>
END
chomp $right_ret;
is_deeply(
	\@tag,
	[
		$right_ret,
		'!attlist',
		3,
		3,
	],
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('doc3.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<?xml version=\"1.0\" standalone=\"yes\"?>",
		'?xml',
		1,
		1,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
$right_ret = <<"END";
<!DOCTYPE family [
  <!ELEMENT family (parent|child)*>
  <!ELEMENT parent (#PCDATA)>
  <!ELEMENT child (#PCDATA)>
]>
END
chomp $right_ret;
is_deeply(
	\@tag,
	[
		$right_ret,
		'!doctype',
		2,
		1,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<family>',
		'family',
		7,
		1,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<parent>',
		'parent',
		8,
		3,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'Judy',
		'!data',
		8,
		11,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</parent>',
		'/parent',
		8,
		15,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<parent>',
		'parent',
		9,
		3,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'Layard',
		'!data',
		9,
		11,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</parent>',
		'/parent',
		9,
		17,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<child>',
		'child',
		10,
		3,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'Jennifer',
		'!data',
		10,
		10,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</child>',
		'/child',
		10,
		18,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<child>',
		'child',
		11,
		3,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'Brendan',
		'!data',
		11,
		10,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</child>',
		'/child',
		11,
		17,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</family>',
		'/family',
		12,
		1,
	],
);
$right_ret =~ s/^<!DOCTYPE family \[//;
$right_ret =~ s/\]>$//;
$obj->set_text($right_ret, 1);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<!ELEMENT family (parent|child)*>",
		'!element',
		2,
		3,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<!ELEMENT parent (#PCDATA)>",
		'!element',
		3,
		3,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<!ELEMENT child (#PCDATA)>",
		'!element',
		4,
		3,
	],
);

# Test.
$obj = Tag::Reader::Perl->new;
$obj->set_file($data_dir->file('doc4.sgml')->s);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<?xml version=\"1.0\" standalone=\"yes\"?>",
		'?xml',
		1,
		1,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
$right_ret = <<"END";
<!DOCTYPE family [
  <!ELEMENT family (#PCDATA|title|parent|child|image)*>
  <!ELEMENT title (#PCDATA)>
  <!ELEMENT parent (#PCDATA)>
  <!ATTLIST parent role (mother | father) #REQUIRED>
  <!ELEMENT child (#PCDATA)>
  <!ATTLIST child role (daughter | son) #REQUIRED>
  <!NOTATION gif SYSTEM "image/gif">
  <!ENTITY JENN SYSTEM "http://images.about.com/sites/guidepics/html.gif"
    NDATA gif>
  <!ELEMENT image EMPTY>
  <!ATTLIST image source ENTITY #REQUIRED>
  <!ENTITY footer "Brought to you by Jennifer Kyrnin">
]>
END
chomp $right_ret;
is_deeply(
	\@tag,
	[
		$right_ret,
		'!doctype',
		2,
		1,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<family>',
		'family',
		16,
		1,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<title>',
		'title',
		17,
		3,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'My Family',
		'!data',
		17,
		10,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</title>',
		'/title',
		17,
		19,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<parent role=\"mother\">",
		'parent',
		18,
		3,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'Judy',
		'!data',
		18,
		25,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</parent>',
		'/parent',
		18,
		29,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<parent role=\"father\">",
		'parent',
		19,
		3,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'Layard',
		'!data',
		19,
		25,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</parent>',
		'/parent',
		19,
		31,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<child role=\"daughter\">",
		'child',
		20,
		3,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'Jennifer',
		'!data',
		20,
		26,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</child>',
		'/child',
		20,
		34,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<image source=\"JENN\" />",
		'image',
		21,
		3,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<child role=\"son\">",
		'child',
		22,
		3,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'Brendan',
		'!data',
		22,
		21,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</child>',
		'/child',
		22,
		28,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"\n  &footer;\n",
		'!data',
		22,
		36,
	],
);
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'</family>',
		'/family',
		24,
		1,
	],
);
$right_ret =~ s/^<!DOCTYPE family \[//;
$right_ret =~ s/\]>$//;
$obj->set_text($right_ret, 1);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<!ELEMENT family (#PCDATA|title|parent|child|image)*>",
		'!element',
		2,
		3,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<!ELEMENT title (#PCDATA)>",
		'!element',
		3,
		3,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<!ELEMENT parent (#PCDATA)>",
		'!element',
		4,
		3,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<!ATTLIST parent role (mother | father) #REQUIRED>",
		'!attlist',
		5,
		3,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<!ELEMENT child (#PCDATA)>",
		'!element',
		6,
		3,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<!ATTLIST child role (daughter | son) #REQUIRED>",
		'!attlist',
		7,
		3,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<!NOTATION gif SYSTEM \"image/gif\">",
		'!notation',
		8,
		3,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!ENTITY JENN SYSTEM '.
			'"http://images.about.com/sites/guidepics/html.gif"'.
			"\n    NDATA gif>",
		'!entity',
		9,
		3,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!ELEMENT image EMPTY>',
		'!element',
		11,
		3,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		'<!ATTLIST image source ENTITY #REQUIRED>',
		'!attlist',
		12,
		3,
	],
);
@tag = $obj->gettoken;
@tag = $obj->gettoken;
is_deeply(
	\@tag,
	[
		"<!ENTITY footer \"Brought to you by Jennifer Kyrnin\">",
		'!entity',
		13,
		3,
	],
);
