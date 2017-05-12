use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Solr',
    VERSION_FROM      => 'lib/Solr.pm', # finds $VERSION
    PREREQ_PM         => {POSIX => '',
                          File::Slurp => '',
                          Log::Log4perl => '1.14',
                          LWP::UserAgent => '',
                          HTTP::Request => '',
                          XML::Simple => '',
                          }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Solr.pm', # retrieve abstract from module
       AUTHOR         => 'Timothy Garafola <garafolat@localdomain>') : ()),
);
