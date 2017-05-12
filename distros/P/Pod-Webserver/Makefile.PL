use 5.004; # Sane minimum, I think.
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
		AUTHOR   => 'Sean M. Burke C<sburke@cpan.org>',
		ABSTRACT => 'Minimal web server for local Perl documentation',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Pod-Webserver-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Pod-Webserver',
	EXE_FILES => ['bin/podwebserver'],
	NAME      => 'Pod::Webserver',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'File::Spec' => 0,
		'File::Spec::Unix' => 0,
		'IO::Socket' => 0,
		'Pod::Simple' => 3.01,
		'Pod::Simple::HTML' => 0,
		'Pod::Simple::HTMLBatch' => 0,
		'Pod::Simple::Progress' => 0,
		'strict' => 0,
		'Test::More' => 1.001014,
		'Test::Pod' => 1.48,
		'Test::TCP' => 2.02,
		'Test::Version' => 1.002003,
		'warnings' => 0,
	},
	VERSION_FROM => 'lib/Pod/Webserver.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'artistic_2';
}

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		resources =>
		{
		'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Webserver',
		'license' => 'http://opensource.org/licenses/Artistic-2.0',
		'repository' => 'https://github.com/ronsavage/Pod-Webserver',
		},
	};
}

WriteMakefile(%params);
