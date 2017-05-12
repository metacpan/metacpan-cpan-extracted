use strict;
use warnings;

use ExtUtils::MakeMaker;

# -----------------------------------------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Parse a Perl regexp into a Tree',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Regexp-Parsertron-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Regexp-Parsertron',
	NAME      => 'Regexp::Parsertron',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Data::Section::Simple'	=> 0.07,
		'File::Slurper'			=> 0.008,
		'Marpa::R2'				=> 3.000000,
		'Moo'					=> 2.001001,
		're'					=> 0,
		'Scalar::Does'			=> 0.202,
		'strict'				=> 0,
		'Test::More'			=> 1.001014,
		'Test::Pod'				=> 1.48,
		'Tree'					=> 1.07,
		'Try::Tiny'				=> 0.24,
		'Types::Standard'		=> 1.000005,
		'warnings'				=> 0,
	},
	VERSION_FROM => 'lib/Regexp/Parsertron.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'artistic_2';
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
		'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Parsertron',
		'license' => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
		'type' => 'git',
		'url' => 'https://github.com/ronsavage/Regexp-Parsertron.git',
		'web' => 'https://github.com/ronsavage/Regexp-Parsertron',
			},
		},
	};
}

WriteMakefile(%params);
