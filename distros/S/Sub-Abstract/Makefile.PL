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
	NAME          => 'Sub::Abstract',
	AUTHOR        => q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM  => 'lib/Sub/Abstract.pm',
	ABSTRACT_FROM => 'lib/Sub/Abstract.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	  ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE' => 'gpl') : ()),
	PREREQ_PM => {
		'Attribute::Handlers'      => 0,
		'Carp'                     => 0,
		'Params::Validate::Strict' => 0.33,
		'Readonly'                 => 0,
		'Return::Set'              => 0,
	},
	TEST_REQUIRES => {
		'IPC::System::Simple' => 0,
		'Moo' => 0,
		'Test::DescribeMe'    => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => 0,
		'Test::Most'          => 0,
		'Test::Needs'         => 0,
		'Test::NoWarnings'    => 0,
		'Test::Returns' => 0,
	},
	clean   => { FILES => 'Sub-Abstract-*' },
	dist    => $dist,
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			homepage   => 'https://metacpan.org/pod/Sub::Abstract',
			repository => {
				type => 'git',
				url  => 'git://github.com/nigelhorne/Sub-Abstract.git',
				web  => 'https://github.com/nigelhorne/Sub-Abstract',
			},
			bugtracker => {
				web    => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Sub-Abstract',
				url    => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Sub-Abstract',
				mailto => 'bug-Sub-Abstract@rt.cpan.org',
			},
		},
	},
	MIN_PERL_VERSION => '5.008',
);
