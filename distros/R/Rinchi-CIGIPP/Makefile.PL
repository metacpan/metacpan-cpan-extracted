use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Rinchi::CIGIPP',
    VERSION_FROM      => 'lib/Rinchi/CIGIPP.pm', # finds $VERSION
    PREREQ_PM         => {Carp => 1.00, IO::Select => 1.00, IO::Socket => 1.00}, # e.g., Module::Name => 1.1 , Exporter => 5.58
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Rinchi/CIGIPP.pm', # retrieve abstract from module
       AUTHOR         => 'Brian M. Ames <bames@localdomain>') : ()),
);

