use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
	NAME               => 'Monitoring::Sneck::Checks',
	AUTHOR             => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
	VERSION_FROM       => 'lib/Monitoring/Sneck/Checks.pm',
	ABSTRACT_FROM      => 'lib/Monitoring/Sneck/Checks.pm',
	LICENSE            => 'lgpl_2_1',
	MIN_PERL_VERSION   => '5.014',
	INST_SCRIPT        => 'bin',
	EXE_FILES          => [ 'src_bin/sneck_check', ],
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'Data::Validate::Domain' => '0',
		'Data::Validate::IP'     => '0',
		'File::Slurp'            => '0',
		'Filesys::Df'            => '0',
		'HTTP::Status'           => '0',
		'IO::Socket::IP'         => '0',
		'IO::Socket::SSL'        => '2.000',
		'JSON'                   => '0',
		'LWP'                    => '6.00',
		'LWP::Protocol::https'   => '0',
		'Net::DNS'               => '1.00',
		'Net::IP'                => '0',
		'Net::Ping'              => '2.41',
		'Net::SSLeay'            => '1.80',
		'Pod::Usage'             => '0',
		'Proc::ProcessTable'     => '0',
		'Time::HiRes'            => '0',
		'URI'                    => '0',
		'XML::LibXML'            => '0',
	},
	dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean      => { FILES    => 'Monitoring-Sneck-Checks-* t/tmp' },
	META_MERGE => {
		"meta-spec" => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => 'git@github.com:VVelox/Monitoring-Sneck-Checks.git',
				web  => 'https://github.com/VVelox/Monitoring-Sneck-Checks',
			},
		},
	}
);

# load and memory read sysctls through it on FreeBSD, and it only builds there
if ( $^O eq 'freebsd' ) {
	$WriteMakefileArgs{PREREQ_PM}{'BSD::Sysctl'} = '0';
}

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
