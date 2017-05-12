use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SQLite::More',
    VERSION_FROM      => 'lib/SQLite/More.pm', # finds $VERSION
    PREREQ_PM         => {
			  'DBD::SQLite' => 1.27,
			  'DBI'         => 1.609,
			  'Digest::MD5' => 0.01, 
			  'Carp'        => 0.01, 
			 #'Acme::Tools' => 0.10,
			 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SQLite/More.pm', # retrieve abstract from module
       AUTHOR         => 'Kjetil Skotheim <kjetilskotheim@gmail.com>') : ()),
);
