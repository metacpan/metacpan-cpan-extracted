use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Plack::Middleware::Debug::Dancer::TemplateTimer',
    AUTHOR             => q{Peter Mottram (SysPete) <peter@sysnix.com>},
    VERSION_FROM       => 'lib/Plack/Middleware/Debug/Dancer/TemplateTimer.pm',
    ABSTRACT_FROM      => 'lib/Plack/Middleware/Debug/Dancer/TemplateTimer.pm',
    LICENSE            => 'perl_5',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'Class::Method::Modifiers' => 0,
        'Dancer'                   => 0,
        'Plack::Middleware::Debug' => 0,
        'Time::HiRes'              => 0,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES => 'Plack-Middleware-Debug-Dancer-TemplateTimer-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/SysPete/Plack-Middleware-Debug-Dancer-TemplateTimer.git',
            bugtracker => 'https://github.com/SysPete/Plack-Middleware-Debug-Dancer-TemplateTimer/issues',
            IRC => 'irc://irc.perl.org/#dancer',
        },
    },
);
