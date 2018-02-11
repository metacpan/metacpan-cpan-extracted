#!/usr/bin/env perl

use v5.10.1;
use strict;
use warnings;

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
	DISTNAME			=> 'Regexp-Parsertron',
	MIN_PERL_VERSION	=> 5.10.1,
	NAME				=> 'Regexp::Parsertron',
	PL_FILES 			=> {},
	PREREQ_PM			=>
	{
		'Capture::Tiny'			=> 0.46,
		'Data::Section::Simple'	=> 0.07,
		'File::Slurper'			=> 0.011,
		'Marpa::R2'				=> 4.000000,
		'Moo'					=> 2.003004,
		'Scalar::Does'			=> 0.203,
		'strict'				=> 0,
		'Tree'					=> 1.10,
		'Try::Tiny'				=> 0.30,
		'Types::Standard'		=> 1.002001,
		'warnings'				=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001002,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM => 'lib/Regexp/Parsertron.pm',
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
			bugtracker	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Parsertron',
			license		=> 'http://opensource.org/licenses/Artistic-2.0',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Regexp-Parsertron.git',
				web		=> 'https://github.com/ronsavage/Regexp-Parsertron',
			},
		},
	};
}

WriteMakefile(%params);
