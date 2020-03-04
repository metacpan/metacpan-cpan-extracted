use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Shell::Run',
    AUTHOR           => q{Jörg Sommrey <git@sommrey.de>},
    VERSION_FROM     => 'lib/Shell/Run.pm',
    ABSTRACT_FROM    => 'lib/Shell/Run.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
		'Test2::V0' => 0,
    },
    PREREQ_PM => {
		'Exporter::Tiny' => 0.025,
		'IPC::Open2' => 0,
		'IO::Select' => 0,
		'File::Which' => 0,
		'Encode' => 0,
		'Carp'	=> 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Shell-Run-*' },
	META_MERGE => {
		"meta-spec" => { version => 2 },
		resources => {
			bugtracker => {
				web => 'https://github.com/jo-37/shell-run/issues',
			},
			repository => {
				type => 'git',
				url => 'git://github.com/jo-37/shell-run.git',
				web => 'https://github.com/jo-37/shell-run',
			},
		},
	},
);
