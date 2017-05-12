use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Schedule::Week',
    VERSION_FROM      => 'lib/Schedule/Week.pm', # finds $VERSION
    PREREQ_PM         => {
        'Readonly' => 0,  # Readonly::XS recommended too for speed but not req.
        'Carp' => 0
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Schedule/Week.pm', # retrieve abstract from module
       AUTHOR         => 'Max Schubert <max_schubert@cable.comcast.com>') : ()),
);
