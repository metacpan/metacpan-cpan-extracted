#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'Acrux'                 => 0.07,    # Ubuntu = libacrux-perl                RHEL = perl-Acrux
        'Acrux::DBI'            => 0.03,    # Ubuntu = libacrux-dbi-perl            RHEL = perl-Acrux-DBI
        'Mojolicious'           => 7.94,    # Ubuntu = libmojolicious-perl          RHEL = perl-Mojolicious
        'WWW::Suffit'           => 1.09,    # Ubuntu = libwww-suffit-perl           RHEL = perl-WWW-Suffit
        'WWW::Suffit::Client'   => 1.03,    # Ubuntu = libwww-suffit-client-perl    RHEL = perl-WWW-Suffit-Client
        'WWW::Suffit::Server'   => 1.12,    # Ubuntu = libwww-suffit-server-perl    RHEL = perl-WWW-Suffit-Server
        'WWW::Suffit::Model'    => 1.01,    # Ubuntu = libwww-suffit-model-perl     RHEL = perl-WWW-Suffit-Model
        'WWW::Suffit::Plugin::BasicAuth'    => 1.00, # Ubuntu = libwww-suffit-plugin-basicauth-perl     RHEL = perl-WWW-Suffit-Plugin-BasicAuth
        'WWW::Suffit::Plugin::ConfigAuth'   => 1.00, # Ubuntu = libwww-suffit-plugin-configauth-perl    RHEL = perl-WWW-Suffit-Plugin-ConfigAuth
        'WWW::Suffit::Plugin::FileAuth'     => 1.00, # Ubuntu = libwww-suffit-plugin-fileauth-perl      RHEL = perl-WWW-Suffit-Plugin-FileAuth
        'WWW::Suffit::Plugin::ServerInfo'   => 1.01, # Ubuntu = libwww-suffit-plugin-serverinfo-perl    RHEL = perl-WWW-Suffit-Plugin-ServerInfo
    };

WriteMakefile(
    'NAME'              => 'Suffit',
    'MIN_PERL_VERSION'  => 5.020001,
    'VERSION_FROM'      => 'lib/Suffit.pm',
    'ABSTRACT_FROM'     => 'lib/Suffit.pm',
    'BUILD_REQUIRES'    => $build_requires,
    'PREREQ_PM'         => $prereq_pm,
    'AUTHOR'            => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'           => 'perl',
    'META_MERGE'        => {
        'meta-spec' => {version => 2},
        prereqs     => {runtime => {requires => {perl => '5.020'}}},
        resources   => {
            homepage    => 'https://sourceforge.net/projects/suffit/',
            license     => 'https://dev.perl.org/licenses',
            repository      => {
                type => 'git',
                url  => 'https://abalama@git.code.sf.net/p/suffit/code',
                web  => 'https://sourceforge.net/p/suffit/code/ci/master/tree/',
            },
        },
    },
    clean => {
        FILES => '*.tmp',
    },
);

1;
