use strict;
use warnings;

use ExtUtils::MakeMaker;

# ----------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Scripts to cross-check Build.PL/Makefile.PL with Module::CoreList, etc',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Module-Metadata-CoreList-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Module-Metadata-CoreList',
	NAME      => 'Module::Metadata::CoreList',
# Next line runs copy.config.pl when user runs 'make'.
# Warning: '...' => 0 is OK but => '' or undef are ignored.
	PL_FILES  => {'scripts/copy.config.pl' => 'Copying...'},
	PREREQ_PM =>
	{	# Deliberately do not use version numbers in most cases.
	# This makes it easier to test the module on itself.
	# See t/test.corelist.t for details.
		'Capture::Tiny'		=> 0,
		'Config'			=> 0,
		'Config::Tiny'		=> 0,
		'Date::Simple'		=> 0,
		'File::Copy'		=> 0,
		'File::HomeDir'		=> 0.99,
		'File::Spec'		=> 0,
		'Getopt::Long'		=> 0,
		'Module::CoreList'	=> 2.61,
		'Moo'				=> 0,
		'Path::Class'		=> 0,
		'Pod::Usage'		=> 0,
		'strict'			=> 0,
		'Text::Xslate'		=> 0,
		'Types::Standard'	=> 0,
		'warnings'			=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More' => 1.001002,
		'Test::Pod' => 0,
	},
	VERSION_FROM => 'lib/Module/Metadata/CoreList.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'perl';
}

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		'meta-spec' =>
		{
			'version' => 2,
		},
		resources   =>
		{
			'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Metadata-CoreList',
			repository =>
			{
				'type' => 'git',
				'url' => 'https://github.com/ronsavage/Module-Metadata-CoreList.git',
				'web' => 'https://github.com/ronsavage/Module-Metadata-CoreList',
			},
		},
	};
}

WriteMakefile(%params);
