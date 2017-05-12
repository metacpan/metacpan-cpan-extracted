use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sys::Syslog::OO',
    VERSION_FROM      => 'lib/Sys/Syslog/OO.pm', # finds $VERSION
    PREREQ_PM         => {
        'Sys::Syslog' => 0,
        'Carp'        => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Sys/Syslog/OO.pm', # retrieve abstract from module
       AUTHOR         => 'Max Schubert <mschuber@local>') : ()),
);
