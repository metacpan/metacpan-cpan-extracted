use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX   => 'gz',
};

if ($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME          => 'Sub::Private',
	AUTHOR        => q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM  => 'lib/Sub/Private.pm',
	ABSTRACT_FROM => 'lib/Sub/Private.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	  ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE' => 'perl') : ()),
	PREREQ_PM => {
		'Attribute::Handlers'      => 0,
		'B::Hooks::EndOfScope'     => 0,
		'Carp'                     => 0,
		# Not used directly.  Return::Set loads Params::Get, whose released
		# versions (<= 0.17) "use autodie qw(:all)", which needs this at
		# load time but only list it in TEST_REQUIRES.  Remove once a fixed
		# Params::Get is out, and require that version here instead.
		'IPC::System::Simple'      => 0,
		'namespace::clean'         => 0,
		'Params::Validate::Strict' => 0.33,
		'Readonly'                 => 0,
		'Return::Set'              => 0,
		'Sub::Identify'            => 0,
	}, TEST_REQUIRES => {
		'File::Spec'          => 0,
		'File::Temp'          => 0,
		'Test::DescribeMe'    => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Most'          => 0,
		'Test::Needs'         => 0,
		'Test::NoWarnings'    => 0,
	},
	clean   => { FILES => 'Sub-Private-*' },
	dist    => $dist,
	META_MERGE => {
		'meta-spec' => { version => 2 },
		prereqs => {
			test => {
				recommends => {
					'Moo'               => 0,
					'Moose'             => 0,
					'Test::Mockingbird' => 0,
					'Test::Returns'     => 0,
				},
			},
		},
		resources => {
			homepage   => 'https://metacpan.org/pod/Sub::Private',
			repository => {
				type => 'git',
				url  => 'https://github.com/nigelhorne/Sub-Private.git',
				web  => 'https://github.com/nigelhorne/Sub-Private',
			},
			bugtracker => {
				web    => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Sub-Private',
				url    => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Sub-Private',
				mailto => 'bug-Sub-Private@rt.cpan.org',
			},
		},
	},
	MIN_PERL_VERSION => '5.014',
);
