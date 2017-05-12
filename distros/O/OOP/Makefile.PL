use strict;
use warnings;
use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'OOP',
    VERSION_FROM      => 'lib/OOP.pm', # finds $VERSION
    PREREQ_PM         => {
                           strict => 0,
                           Carp   => 0,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/OOP.pm', # retrieve abstract from module
       AUTHOR         => 'Milan Adamovsky <milan@adamovsky.com>') : ()),
);
