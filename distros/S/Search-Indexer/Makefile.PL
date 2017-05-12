use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Search::Indexer',
    VERSION_FROM      => 'lib/Search/Indexer.pm', # finds $VERSION
    PREREQ_PM         => {'Search::QueryParser' => '0.91',
			  'BerkeleyDB'          => '0.22',
                          'List::MoreUtils'     => 0},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Search/Indexer.pm', # retrieve abstract from module
       AUTHOR         => 'Laurent Dami <laurent.dami AT etat ge ch>') : ()),
);
