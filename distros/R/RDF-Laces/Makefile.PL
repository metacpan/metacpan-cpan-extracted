use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'RDF::Laces',
    VERSION_FROM      => 'Laces.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Laces.pm', # retrieve abstract from module
       AUTHOR         => 'Ashley Winters <awinters@users.sourceforge.net>') : ()),
);
