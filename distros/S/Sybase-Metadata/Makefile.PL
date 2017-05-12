use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sybase::Metadata',
    VERSION_FROM      => 'lib/Sybase/Metadata.pm', # finds $VERSION
    PREREQ_PM         => {'DBI'      => '1.601',
                          'DBD::Sybase'   => '1.08'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Sybase/Metadata.pm', # retrieve abstract from module
       AUTHOR         => 'Mike O\'Brien <mikeob@>') : ()),
);
