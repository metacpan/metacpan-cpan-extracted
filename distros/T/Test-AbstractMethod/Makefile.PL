#!perl

use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'Test::AbstractMethod',
    VERSION_FROM      => 'lib/Test/AbstractMethod.pm', # finds $VERSION
    LICENSE           => 'perl',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/AbstractMethod.pm', # retrieve abstract from module
      AUTHOR         => 'Claes Jakobsson <claesjac@cpan.org>') : ()),
);
