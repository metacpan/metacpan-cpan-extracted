use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Template::Provider::OpenOffice',
    VERSION_FROM      => 'lib/Template/Provider/OpenOffice.pm', # finds $VERSION
    PREREQ_PM         => { OpenOffice::OODoc::File => 2.113, Template::Provider => 2.15}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Provider/OpenOffice.pm', # retrieve abstract from module
       AUTHOR         => 'Andy Brezinsky <abrezinsky@brevient.com>') : ()),
);
