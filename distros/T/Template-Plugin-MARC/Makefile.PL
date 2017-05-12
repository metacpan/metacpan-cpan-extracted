use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Template::Plugin::MARC',
    LICENSE           => 'gpl_3',
    VERSION_FROM      => 'lib/Template/Plugin/MARC.pm', # finds $VERSION
    NO_META           => 1,
    PREREQ_PM         =>  { 'MARC::Record' => 2,
                            'Template' => 2.22 }, # e.g., Module::Name => 1.1
    EXE_FILES         => [ 'bin/batch-marc-tt' ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Plugin/MARC.pm', # retrieve abstract from module
       AUTHOR         => 'Jared Camins-Esakov <jcamins@cpbibliography.com>') : ()),
);
