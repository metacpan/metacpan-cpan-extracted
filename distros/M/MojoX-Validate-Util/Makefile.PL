#!/usr/bin/env perl

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
		ABSTRACT => 'A very convenient wrapper around Mojolicious::Validator',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST MojoX-Validate-Util-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'MojoX-Validate-Util',
	NAME      => 'MojoX::Validate::Util',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Mojolicious'				=> 7.38,
		'Mojolicious::Validator'	=> 0,
		'Moo'						=> 2.003000,
		'Params::Classify'			=> 0.013,
		'strict'					=> 0,
		'Types::Standard'			=> 1.002001,
		'URI::Find::Schemeless'		=> 20160806,
		'warnings'					=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001002,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM => 'lib/MojoX/Validate/Util.pm',
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
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=MojoX-Validate-Util',
			},
			license    => 'http://dev.perl.org/licenses/',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/MojoX-Validate-Util.git',
				web  => 'https://github.com/ronsavage/MojoX-Validate-Util',
			},
		},
	};
}

WriteMakefile(%params);
