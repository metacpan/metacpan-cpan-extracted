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
		ABSTRACT => 'Address SVG images using cells of $n1 x $n2 pixels',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST SVG-Grid-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'SVG-Grid',
	NAME      => 'SVG::Grid',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'File::Slurper'		=> 0.009,
		'Getopt::Long'		=> 0,
		'Moo'				=> 2.002004,
		'Pod::Usage'		=> 0,
		'strict'			=> 0,
		'SVG'				=> 2.64,
		'Types::Standard'	=> 1.000005,
		'warnings'			=> 0,
	},
	TEST_REQUIRES =>
	{
		'File::Spec'		=> 0,
		'File::Temp'		=> 0,
		'Test::Pod'			=> 1.51,
		'Test::Simple'		=> 1.302052, # For Test::More.
	},
	VERSION_FROM => 'lib/SVG/Grid.pm',
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
			version => 2,
		},
		resources =>
		{
			bugtracker =>
			{
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=SVG-Grid',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/SVG-Grid.git',
				web		=> 'https://github.com/ronsavage/SVG-Grid',
			},
		},
	};
}

WriteMakefile(%params);
