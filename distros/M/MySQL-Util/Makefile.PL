use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME               => 'MySQL::Util',
	AUTHOR             => q{John Gravatt <gravattj@cpan.org>},
	VERSION_FROM       => 'lib/MySQL/Util.pm',
	ABSTRACT_FROM      => 'lib/MySQL/Util.pm',
	LICENSE            => 'artistic_2',
	PL_FILES           => {},
	MIN_PERL_VERSION   => '5.006',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	BUILD_REQUIRES => {
		'Test::More'  => 0,
		'File::Which' => 0,
	},
	PREREQ_PM => {
		'DBI'                  => 0,
		'DBD::mysql'           => 0,
		'Test::More'           => 0,
		'Method::Signatures'   => 0,
		'Data::Printer'        => 0,
		'Moose'                => 1.24,
		'Moose::Role'          => 0,
		'namespace::autoclean' => 0,
		'Data::Compare'        => 1.22,
		'String::Util'         => 0,
		'autodie'              => 0,
		'Modern::Perl'         => 0,
		'DBIx::DataFactory'    => 0,
		'List::MoreUtils'      => 0,
		'SQL::Beautify'        => 0,
		'Smart::Args'          => 0,
		'Symbol::Util'         => 0,
		'Config::General'      => 0,
		'Module::Load'         => 0,
	},
	EXE_FILES => [
		"bin/myutil_create_data.pl",
		"bin/myutil_dump_table_constraints.pl",
		"bin/myutil_dump_table_fks.pl",
		"bin/myutil_dump_tables.pl"
	],
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES    => 'MySQL-Util-*' },
);
