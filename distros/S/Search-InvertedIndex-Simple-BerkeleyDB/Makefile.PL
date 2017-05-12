use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
	 'AUTHOR'   => 'Ron Savage (ron@savage.net.au)',
	 'ABSTRACT' => 'Build indexes for a set of search keys; Search using BerkeleyDB',
    ) : (),
	clean =>
	{
	 FILES => 'blib/* Makefile MANIFEST Search-InvertedIndex-Simple-BerkeleyDB*'
	},
	dist =>
	{
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
	},
	DISTNAME  => 'Search-InvertedIndex-Simple-BerkeleyDB',
	NAME      => 'Search::InvertedIndex::Simple::BerkeleyDB',
	PL_FILES  => {},
	PREREQ_PM =>
	{
	 BerkeleyDB                    => 0.41,
	 Search::InvertedIndex::Simple => 1.03,
	 Set::Array                    => 0.19,
	 Test::More                    => 0.94,
	 Test::Pod                     => 1.41,
	},
	VERSION_FROM => 'lib/Search/InvertedIndex/Simple/BerkeleyDB.pm',
);
