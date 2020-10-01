use 5.016;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Mojolicious::Plugin::AccessLog',
    VERSION_FROM   => 'lib/Mojolicious/Plugin/AccessLog.pm',
    ABSTRACT       => 'An AccessLog Plugin for Mojolicious',
    AUTHOR         => 'Bernhard Graf',
    BUILD_REQUIRES => {
        'POSIX'               => 0,
        'Time::Local'         => 0,
    },
    LICENSE        => 'perl_5',
    META_MERGE     => {
        requires   => {perl => '5.016'},
        resources  => {
            license    => 'http://dev.perl.org/licenses/',
            bugtracker => 'https://github.com/augensalat/mojolicious-plugin-accesslog/issues',
            repository => 'https://github.com/augensalat/mojolicious-plugin-accesslog.git',
        },
    },
    PREREQ_PM      => {
        'Mojolicious'  => '3.28',
        'IO::File'     => 0,
        'Scalar::Util' => 0,
        'Socket'       => 0,
        'Time::HiRes'  => 0,
        'File::Spec'   => 0,
    },
    test           => {TESTS => 't/*.t'}

);
