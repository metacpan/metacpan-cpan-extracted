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
		ABSTRACT => 'A Set of Discrete Finite Automata',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Set-FA-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Set-FA',
	NAME      => 'Set::FA',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Capture::Tiny'		=> 0.44,
		'Log::Handler'		=> 0.88,
		'Moo'				=> 2.002004,
		'parent'			=> 0.234,
		'Set::Object'		=> 1.35,
		'strict'			=> 0,
		'Types::Standard'	=> 1.000005,
		'warnings'			=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::Pod'		=> 1.51,
		'Test::More'	=> 1.302056,
	},
	VERSION_FROM => 'lib/Set/FA.pm',
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
		resources   =>
		{
			bugtracker =>
			{
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Set-FA',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				'type' => 'git',
				'url' => 'https://github.com/ronsavage/Set-FA.git',
				'web' => 'https://github.com/ronsavage/Set-FA',
			},
		},
	};
}

WriteMakefile(%params);
