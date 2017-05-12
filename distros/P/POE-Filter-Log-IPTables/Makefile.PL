use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POE::Filter::Log::IPTables',
    VERSION_FROM      => 'IPTables.pm', # finds $VERSION
    PREREQ_PM         => {POE => 0.29}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'IPTables.pm', # retrieve abstract from module
       AUTHOR         => 'Paul Visscher <paulv@cpan.org>') : ()),
);
