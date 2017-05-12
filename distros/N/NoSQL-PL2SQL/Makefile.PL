use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'NoSQL::PL2SQL',
    VERSION_FROM      => 'lib/NoSQL/PL2SQL.pm', # finds $VERSION
    PREREQ_PM         => {
			XML::Parser => 2.41,
			XML::Parser::Nodes => 0.08,
			DBI => 1.57,
			DBD::SQLite => 1.37,	## For testing
			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/NoSQL/PL2SQL.pm', # retrieve abstract from module
       AUTHOR         => 'Jim Schueler <jim@tqis.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
