use strict;
use warnings;

use ExtUtils::MakeMaker;

eval "use ExtUtils::MakeMaker::Coverage";

if ( $@ )
{
	print "Skipping testcover target, ExtUtils::MakeMaker::Coverage not found\n";
}
else
{
	print "Adding testcover target\n";
}

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'David Landgren',
		ABSTRACT => 'Assemble multiple Regular Expressions into a single RE',
	) : (),
	clean =>
	{
		FILES => 'cover_db blib/* Makefile MANIFEST Regexp-Assemble-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Regexp-Assemble',
	NAME      => 'Regexp::Assemble',
	PREREQ_PM =>
	{
		'constant' => 0,
		'strict' => 0,
		'Test::More' => 1.001014,
		'Test::Pod' => 1.48,
		'vars' => 0,
		'warnings' => 0,
	},
	VERSION_FROM => 'lib/Regexp/Assemble.pm',
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
			'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Assemble',
			repository =>
			{
				'type' => 'git',
				'url' => 'https://github.com/ronsavage/Regexp-Assemble.git',
				'web' => 'https://github.com/ronsavage/Regexp-Assemble',
			},
		},
	};
}

WriteMakefile(%params);
