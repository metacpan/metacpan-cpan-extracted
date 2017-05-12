use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojo::Log::More',
    AUTHOR           => 'Olivier Duclos <odc@cpan.org>',
    VERSION_FROM     => 'lib/Mojo/Log/More.pm',
    ABSTRACT_FROM    => 'lib/Mojo/Log/More.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Mojolicious' => '5.0',
        'Time::Piece' => 0,
        'File::Spec'  => 0,
    },
    META_MERGE       => {
        requires     => { perl => '5.010' },
        resources    => {
            license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
            repository => 'http://github.com/oliwer/mojo-log-more',
            bugtracker => 'http://github.com/oliwer/mojo-log-more/issues'
        },
        no_index     => { directory => ['t'] }
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojo-Log-More-*' },
);
