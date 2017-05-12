use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		'AUTHOR'  => 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT' => 'Build indexes for a set of search keys',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Search-InvertedIndex-Simple-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Search-InvertedIndex-Simple',
	NAME      => 'Search::InvertedIndex::Simple',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		Set::Array => 0.19,
		strict     => 1.03,
		Test::More => 0,
		Test::Pod  => 0,
		warnings   => 1.03,
	},
	VERSION_FROM => 'lib/Search/InvertedIndex/Simple.pm',
);
