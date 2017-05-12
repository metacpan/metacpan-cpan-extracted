use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Module::AutoLoad',
    VERSION_FROM      => 'lib/Module/AutoLoad.pm', # finds $VERSION
    PREREQ_PM         => {}, # NONE!
    ABSTRACT_FROM     => 'lib/Module/AutoLoad.pm',
    AUTHOR            => 'Rob Brown (bbb@cpan.org)',
);
