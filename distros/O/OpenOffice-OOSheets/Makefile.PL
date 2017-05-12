use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'OpenOffice::OOSheets',
    VERSION_FROM      => 'lib/OpenOffice/OOSheets.pm', # finds $VERSION
    PREREQ_PM         => {XML::Parser}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/OpenOffice/OOSheets.pm', # retrieve abstract from module
       AUTHOR         => 'Zahatski Aliaksandr, <zagap@users.sourceforge.net>') : ()),
);
