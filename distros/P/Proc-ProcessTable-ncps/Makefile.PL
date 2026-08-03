use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
	NAME               => 'Proc::ProcessTable::ncps',
	AUTHOR             => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
	VERSION_FROM       => 'lib/Proc/ProcessTable/ncps.pm',
	ABSTRACT_FROM      => 'lib/Proc/ProcessTable/ncps.pm',
	LICENSE            => 'artistic_2',
	MIN_PERL_VERSION   => '5.010001',
	EXE_FILES          => ['src_bin/ncps'],
	INST_SCRIPT        => 'bin',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'Term::ANSIColor'                => '5.01',
		'Text::ANSITable'                => '0.501',
		# Text::ANSI::Util 0.233 calls Text::WideChar::Util::_mbs_indent_width,
		# which no longer exists as of Text::WideChar::Util 0.172
		'Text::ANSI::Util'               => '0.234',
		'Text::WideChar::Util'           => '0.172',
		'Getopt::Long'                   => '0',
		'Data::Unixish::Apply'           => '1.572',
		'Proc::ProcessTable'             => '0.634',
		'Proc::ProcessTable::Match'      => '0.1.0',
		'POSIX'                          => '0',
		'Statistics::Basic'              => '1.6611',
		'List::Util'                     => '0',
		# 0.2.0 for proc_infostring_describe
		'Proc::ProcessTable::InfoString' => '0.2.0',
		# Text::ANSITable loads these by name, so they are not prereqs of it
		'ColorTheme::NoColor'            => '0.003',
		'BorderStyle::ASCII::None'       => '0.014',
	},
	dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean      => { FILES    => 'Proc-ProcessTable-ncps-*' },
	META_MERGE => {
		"meta-spec" => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => 'git@github.com:VVelox/Proc-ProcessTable-ncps.git',
				web  => 'https://github.com/VVelox/Proc-ProcessTable-ncps',
			},
		},
	}

);

# Compatibility with old versions of ExtUtils::MakeMaker
unless ( eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 } ) {
	my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
	@{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$test_requires } = values %$test_requires;
}

unless ( eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 } ) {
	my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
	@{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$build_requires } = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
	unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
	unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
	unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
