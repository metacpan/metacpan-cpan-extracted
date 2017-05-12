use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Module::Install::DiffCheck',
    AUTHOR              => 'Jay Hannah <jay@jays.net>',
    VERSION_FROM        => 'lib/Module/Install/DiffCheck.pm',
    ABSTRACT_FROM       => 'lib/Module/Install/DiffCheck.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'inc::Module::Install'  => 0,
        'Text::Diff::Parser'     => '0.1000',  # https://rt.cpan.org/Ticket/Display.html?id=46426
    },
    META_MERGE => {
         resources => {
             repository  =>  'https://github.com/jhannah/module-install-diffcheck',
         },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Module-Install-DiffCheck-*' },
);
