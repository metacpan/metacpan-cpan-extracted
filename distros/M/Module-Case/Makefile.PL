use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Module::Case',
    VERSION_FROM      => 'lib/Module/Case.pm',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Module/Case.pm',
    AUTHOR            => 'Rob Brown <bbb@cpan.org>',
    LICENSE           => 'mit',
);
