use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'MySQL::Compress',
	'AUTHOR'	=> 'Craig Manley',
	'ABSTRACT'	=> 'This module provides MySQL COMPRESS() and UNCOMPRESS() compatible Perl functions',
	'VERSION_FROM' => 'lib/MySQL/Compress.pm',
	'BUILD_REQUIRES' => {
		'ExtUtils::MakeMaker'	=> 6.48,
		'Test::More'			=> 0,
	},
	'PREREQ_PM' =>	{
		'Compress::Zlib'		=> 0,
	},
	'MIN_PERL_VERSION'	=> 5.010000,
	'LICENSE' => 'perl_5',
	'dist' => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
);
