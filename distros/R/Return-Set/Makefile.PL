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
	NAME	 => 'Return::Set',
	AUTHOR	 => q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM => 'lib/Return/Set.pm',
	ABSTRACT_FROM => 'lib/Return/Set.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES => {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
	}, PREREQ_PM => {
		'Carp' => 0,
		'Exporter' => 0,
		'Params::Get' => 0.11,
		'Params::Validate::Strict' => 0.04,
	}, dist => $dist,
	clean => { FILES => 'Return-Set-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Return::Set',
			repository => {
				repository => 'https://github.com/nigelhorne/Return-Set',
				type => 'git',
				url => 'git://github.com/nigelhorne/Return-Set.git',
				web => 'https://github.com/nigelhorne/Return-Set',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-Return-Set@rt.cpan.org',
				url => 'https://github.com/nigelhorne/Return-Set/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Return-Set',
				web => 'https://github.com/nigelhorne/Return-Set/issues'
			}
		},
	},
	MIN_PERL_VERSION => '5.008'
);
