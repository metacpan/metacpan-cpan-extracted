use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PDF::Table',
    VERSION_FROM      => 'lib/PDF/Table.pm', # finds $VERSION
    LICENSE           => 'perl_5',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PDF/Table.pm', # retrieve abstract from module
       AUTHOR         => 'Desislav Kamenov <omega@cpan.org>') : ()),
    META_MERGE        => {
        resources => {
            bugtracker => 'https://github.com/kamenov/PDF-Table/issues',
            repository => 'https://github.com/kamenov/PDF-Table',
        },
    },
);
