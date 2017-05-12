use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Module::Starter::Plugin::TT2',
    AUTHOR              => 'Ricardo SIGNES <rjbs@cpan.org>',
    VERSION_FROM        => 'lib/Module/Starter/Plugin/TT2.pm',
    ABSTRACT_FROM       => 'lib/Module/Starter/Plugin/TT2.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
		    'Module::Starter' => 1.470, # first v. with Module::Install, ::Template
        'Test::More'      => 0,
        'Template'        => 2,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Module-Starter-Plugin-TT2-*' },
);
