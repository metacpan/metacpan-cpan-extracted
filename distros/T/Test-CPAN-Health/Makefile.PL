use strict;
use warnings;
use ExtUtils::MakeMaker 7.00;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME             => 'Test::CPAN::Health',
	AUTHOR           => q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM     => 'lib/Test/CPAN/Health.pm',
	ABSTRACT_FROM    => 'lib/Test/CPAN/Health.pm',
	LICENSE          => 'gpl_2',
	MIN_PERL_VERSION => '5.014',
	EXE_FILES        => ['scripts/cpan-health'],
	PREREQ_PM        => {
		'Carp'                  => 0,
		'CPAN::Audit'           => 0,
		'CPAN::Meta'            => 0,
		'DBD::SQLite'           => 0,
		'DBI'                   => 0,
		'File::Find::Rule'      => 0,
		'File::Spec'            => 0,
		'File::Temp'            => 0,
		'Getopt::Long'          => 0,
		'HTTP::Tiny'            => 0,
		'JSON::MaybeXS'         => 0,
		'Module::CPANTS::Analyse' => 0,
		'Object::Configure' => 0,
		'Params::Get'           => 0,
		'Params::Validate::Strict' => 0.35,
		'Perl::Critic'          => 0,
		'Perl::Metrics::Simple' => 0,
		'Perl::MinimumVersion'  => 0,
		'Pod::Checker'          => 0,
		'Pod::Coverage'         => 0,
		'Readonly'              => 2.00,
		'Scalar::Util'          => 0,
		'Sub::Protected'        => 0,
		'Term::ANSIColor'       => 0,
		'YAML::Tiny'            => 0,
	}, TEST_REQUIRES => {
		'IPC::System::Simple' => 0,
		'Test::Memory::Cycle'  => 0,
		'Test::Most'  => 0,
		'Test::Returns' => 0,
		'Test::Mockingbird' => 0,
	},
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/nigelhorne/Test-CPAN-Health.git',
				web  => 'https://github.com/nigelhorne/Test-CPAN-Health',
			}, bugtracker => {
				web => 'https://github.com/nigelhorne/Test-CPAN-Health/issues',
			},
		},
	}, dist => $dist,
	clean		=> { FILES => 'Test-CPAN-Health-*' },
	test => { TESTS => 't/*.t t/*/*.t' },
);
