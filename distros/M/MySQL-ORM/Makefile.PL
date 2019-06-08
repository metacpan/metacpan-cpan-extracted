use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME               => 'MySQL::ORM',
	AUTHOR             => q{John Gravatt <gravattj@cpan.org>},
	VERSION_FROM       => 'lib/MySQL/ORM.pm',
	ABSTRACT_FROM      => 'lib/MySQL/ORM.pm',
	LICENSE            => 'artistic_2',
	PL_FILES           => {},
	MIN_PERL_VERSION   => '5.006',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	BUILD_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'MySQL::Util'             => 0.40,
		'Method::Signatures'      => 0,
		'Data::Printer'           => 0,
		'SQL::Abstract::Complete' => 0,
		'Text::Trim'              => 0,
		'Perl::Tidy::Sweetened'   => 0,
		'Module::Refresh'         => 0,
		'Capture::Tiny'           => 0,
	},
	EXE_FILES => ['bin/mysql-orm.pl'],
	dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean     => { FILES => 'MySQL-ORM-*' },
);
