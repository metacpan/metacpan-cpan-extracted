use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	NAME              => 'Parse::SNI',
	LICENSE           => 'perl',
	VERSION_FROM      => 'lib/Parse/SNI.pm', # finds $VERSION
	PREREQ_PM         => {},
	BUILD_REQUIRES    => { 'Test::More' => 0.88 },
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.52,
	},
	META_MERGE        => { 
		resources => { repository => 'https://github.com/olegwtf/p5-Parse-SNI' },
	},
	ABSTRACT_FROM     => 'lib/Parse/SNI.pm', # retrieve abstract from module
	AUTHOR            => 'Oleg G <oleg@cpan.org>'
);
