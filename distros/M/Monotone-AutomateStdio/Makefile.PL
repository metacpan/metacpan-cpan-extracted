use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Monotone::AutomateStdio',
    VERSION_FROM      => 'lib/Monotone/AutomateStdio.pm',
    PREREQ_PM         => {},
    'dist'            => { COMPRESS => 'gzip -9f', SUFFIX => '.gz' },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Monotone/AutomateStdio.pod',
       AUTHOR         => 'Anthony E Cooper <aecooper@coosoft.plus.com>') : ()),
);
