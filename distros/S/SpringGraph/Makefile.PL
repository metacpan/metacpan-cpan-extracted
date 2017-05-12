use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SpringGraph',
    VERSION_FROM      => 'lib/SpringGraph.pm', # finds $VERSION
    PREREQ_PM         => { GD => 1 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      ( AUTHOR         => 'Aaron Trevena <teejay@droogs.org>') : ()),
);
