use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'Readonly::Values::Syslog',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Readonly/Values/Syslog.pm',
	ABSTRACT_FROM	=> 'lib/Readonly/Values/Syslog.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES	=> {},
	EXE_FILES	=> [ 'bin/syslog-utils' ],
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::NoWarnings' => 0,
	}, PREREQ_PM => {
		'Carp' => 0,
		'Exporter' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'Readonly' => 0,
		'Readonly::Enum' => 0,
		'Scalar::Util' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'Readonly-Values-Syslog-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				repository => 'https://github.com/nigelhorne/Readonly-Values-Syslog',
				type => 'git',
				url => 'git://github.com/nigelhorne/Readonly-Values-Syslog.git',
				web => 'https://github.com/nigelhorne/Readonly-Values-Syslog'
			}, bugtracker => {
				mailto => 'bug-Readonly-Values-Syslog@rt.cpan.org',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Readonly-Values-Syslog',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Readonly-Values-Syslog',
				# url => 'https://github.com/nigelhorne/Readonly-Values-Syslog/issues',
				# web => 'https://github.com/nigelhorne/Readonly-Values-Syslog/issues'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.014'
);
