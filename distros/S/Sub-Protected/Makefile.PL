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
	NAME             => 'Sub::Protected',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM     => 'lib/Sub/Protected.pm',
	ABSTRACT_FROM    => 'lib/Sub/Protected.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'gpl_2')
		: ()),
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# For TEST_REQUIRES
	}, PREREQ_PM        => {
		'Attribute::Handlers' => 0,
		'B::Hooks::EndOfScope' => 0,
		'Carp'                => 0,
		'Params::Get' => 0,
		'Params::Validate::Strict' => 0.33,
		'Readonly' => 0,
		'Return::Set' => 0,
		'Sub::Identify' => 0,
	}, TEST_REQUIRES    => {
		'IPC::System::Simple' => 0,
		'Test::DescribeMe' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Most'      => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0,
	},
	clean		=> { FILES => 'Sub-Protected-*' },
	dist => $dist,
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		dynamic_config => 0,
		prereqs => {
			test => {
				# Tests that use these skip without them
				recommends => {
					'Moo' => 0,	# Large; only needed for one subtest
					'Test::Mockingbird' => 0,	# Needs Perl 5.16.3
				},
			},
		},
		provides => {
			'Sub::Protected' => {
				file => 'lib/Sub/Protected.pm',
				version => MM->parse_version('lib/Sub/Protected.pm'),
			},
		},
		resources => {
			homepage => 'https://metacpan.org/pod/Sub::Protected',
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Sub-Protected.git',
				web => 'https://github.com/nigelhorne/Sub-Protected',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Sub-Protected',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Sub-Protected',
				# web => 'https://github.com/nigelhorne/Sub-Protected/issues',
				# url => 'https://github.com/nigelhorne/Sub-Protected/issues',
				mailto => 'bug-Sub-Protected@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.010'
);
