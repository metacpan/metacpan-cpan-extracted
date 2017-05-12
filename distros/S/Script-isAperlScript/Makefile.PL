use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Script::isAperlScript',
	AUTHOR              => 'Zane C. Bowers-Hadley <vvelox@vvelox.net>',
	VERSION_FROM        => 'lib/Script/isAperlScript.pm',
	ABSTRACT_FROM       => 'lib/Script/isAperlScript.pm',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
	 ? ('LICENSE'=> 'perl')
	 : ()),
	PL_FILES            => {},
	PREREQ_PM => {
		'Test::More'=>0,
		'Error::Helper'=>'1.0.0',
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Script-isAperlScript-*' },
	);
