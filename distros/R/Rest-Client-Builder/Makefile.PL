use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Rest::Client::Builder',
	AUTHOR              => 'Alexey A. Komarov <alexkom@cpan.org>',
	VERSION_FROM        => 'lib/Rest/Client/Builder.pm',
	ABSTRACT_FROM       => 'lib/Rest/Client/Builder.pm',
	($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'=> 'perl') : ()),
	PL_FILES            => { },
	PREREQ_PM           => {
		'Test::More'      => '0',
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Rest-Client-Builder-*' },
);
