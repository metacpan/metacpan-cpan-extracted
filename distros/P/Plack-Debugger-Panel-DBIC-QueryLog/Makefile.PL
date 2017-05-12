use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Plack::Debugger::Panel::DBIC::QueryLog',
    AUTHOR             => q{Peter Mottram (SysPete) <peter@sysnix.com>},
    VERSION_FROM       => 'lib/Plack/Debugger/Panel/DBIC/QueryLog.pm',
    ABSTRACT_FROM      => 'lib/Plack/Debugger/Panel/DBIC/QueryLog.pm',
    LICENSE            => 'perl',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'DBIx::Class::QueryLog'             => 0,
        'DBIx::Class::QueryLog::Analyzer'   => 0,
        'Plack'                             => 0,
        'Plack::Middleware::DBIC::QueryLog' => '0.05',
        'Plack::Debugger'                   => 0,
        'Plack::Debugger::Panel'            => 0,
        'SQL::Abstract'                     => '1.70',
        'Text::MicroTemplate'               => 0,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES => 'Plack-Debugger-Panel-DBIC-QueryLog-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/SysPete/Plack-Debugger-Panel-DBIC-QueryLog.git',
            bugtracker => 'https://github.com/SysPete/Plack-Debugger-Panel-DBIC-QueryLog/issues',
        },
    },
);
