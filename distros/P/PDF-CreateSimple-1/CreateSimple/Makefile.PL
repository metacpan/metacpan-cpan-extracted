use 5.008002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PDF::CreateSimple',
    VERSION_FROM      => 'lib/PDF/CreateSimple.pm', # finds $VERSION
    PREREQ_PM         => {'Error'       => 0.15, # for error trapping
                          'PDF::API2'   => 1.081},# the back bone of PDF::CreateSimple
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PDF/CreateSimple.pm', # retrieve abstract from module
       AUTHOR         => 'David Brunelle <david@med.usherbrooke.ca>') : ()),
);