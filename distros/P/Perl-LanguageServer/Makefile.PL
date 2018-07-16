use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Perl::LanguageServer',
    AUTHOR           => q{grichter <richter@ecos.de>},
    VERSION_FROM     => 'lib/Perl/LanguageServer.pm',
    ABSTRACT_FROM    => 'lib/Perl/LanguageServer.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.014',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Moose'              => '0',
        'AnyEvent'           => '0',
        'IO::AIO'            => '0',
        'AnyEvent::AIO'      => '0',
        'Coro'               => '0',
        'JSON'               => '0',
        'Compiler::Lexer'    => '0',
        'Data::Dump'         => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Perl-LanguageServer-*' },
);
