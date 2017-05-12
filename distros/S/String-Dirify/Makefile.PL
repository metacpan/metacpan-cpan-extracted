#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

# ----------------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Convert a string into a directory name',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST String-Dirify-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME		=> 'String-Dirify',
	NAME			=> 'String::Dirify',
	PL_FILES		=> {},
	PREREQ_PM		=>
	{
		Exporter	=> 0,
		strict		=> 0,
		warnings	=> 0,
	},
	TEST_REQUIRES	=>
	{
		'Test::More'	=> 1.001014,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM => 'lib/String/Dirify.pm',
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
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=String-Dirify',
			},
			license    => 'http://dev.perl.org/licenses/',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/String-Dirify.git',
				web  => 'https://github.com/ronsavage/String-Dirify',
			},
		},
	};
}

WriteMakefile(%params);
