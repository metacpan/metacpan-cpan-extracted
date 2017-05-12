use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Pod::Usage::CommandLine',
    VERSION_FROM      => 'lib/Pod/Usage/CommandLine.pm',
    PREREQ_PM         => { File::Basename => 0,
                           Pod::Usage => 0,
                           Getopt::Long => 0 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Pod/Usage/CommandLine.pm',
       AUTHOR         => 'Curt Tilmes <ctilmes@cpan.org>') : ()),
);
