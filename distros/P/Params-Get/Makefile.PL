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
	AUTHOR => 'Nigel Horne <njh@bandsman.co.uk>',
	NAME => 'Params::Get',
	VERSION_FROM => 'lib/Params/Get.pm', # finds $VERSION in the module
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	PREREQ_PM => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'Carp' => 0,
	},
	META_MERGE => {
		resources => {
			repository => {
				type => 'git',
				url => 'https://github.com/nigelhorne/Params-Get.git',
				web => 'https://github.com/nigelhorne/Params-Get',
			},
			bugtracker => {
				web => 'https://github.com/nigelhorne/Params-Get/issues',
			},
		},
	},
	TEST_REQUIRES => {
		'Error' => 0,
		'Test::Compile' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Warnings' => 0
	}, dist => $dist,
	clean => { FILES => 'Params-Get-*' },  # Clean up distribution files
);
