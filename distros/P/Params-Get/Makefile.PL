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
	ABSTRACT_FROM	=> 'lib/Params/Get.pm',
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	NAME => 'Params::Get',
	VERSION_FROM => 'lib/Params/Get.pm', # finds $VERSION in the module
	MIN_PERL_VERSION => '5.010001',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'gpl_2')
		: ()),
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '6.64',
	},
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Params::Get',
			repository => {
				type => 'git',
				url => 'https://github.com/nigelhorne/Params-Get.git',
				web => 'https://github.com/nigelhorne/Params-Get',
			},
			bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Params-Get',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Params-Get',
				mailto => 'bug-Params-Get@rt.cpan.org'
			},
		},
	},
	PREREQ_PM => {
		'Carp' => 0,
		'Readonly' => 0,
		'Scalar::Util' => 0
	}, TEST_REQUIRES => {
		'Error' => 0,
		'IPC::System::Simple' => 0,
		'Params::Validate::Strict' => 0,
		'Test::DescribeMe' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => 0.08,
		'Test::Returns' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Without::Module' => 0,
	}, dist => $dist,
	clean => { FILES => 'Params-Get-*' },  # Clean up distribution files
);
