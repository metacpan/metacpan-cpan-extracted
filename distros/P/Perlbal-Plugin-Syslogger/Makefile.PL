use 5.008009;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Perlbal::Plugin::Syslogger',
    VERSION_FROM    => 'lib/Perlbal/Plugin/Syslogger.pm',
    ABSTRACT_FROM   => 'lib/Perlbal/Plugin/Syslogger.pm',
    AUTHOR          => 'Adam Thomason <athomason@cpan.org>',
    PREREQ_PM       => {
        'Danga::Socket'             => 1.59,
        'Perlbal'                   => 1.76,
        'Log::Syslog::Constants'    => 1.01,
        'Log::Syslog::DangaSocket'  => 1.05,
        'Log::Syslog::Fast'         => 0.48,
    },
);
