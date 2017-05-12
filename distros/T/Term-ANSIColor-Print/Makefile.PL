use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Term::ANSIColor::Print',
    VERSION_FROM      => 'lib/Term/ANSIColor/Print.pm', # finds $VERSION
    PREREQ_PM         => {
        Readonly => '1.02',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Term/ANSIColor/Print.pod', # retrieve abstract from module
       AUTHOR         => 'Dylan Doxey <dylan.doxey@gmail.com>') : ()),
);
