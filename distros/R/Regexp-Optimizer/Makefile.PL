#
# $Id: Makefile.PL,v 0.20 2013/02/23 13:43:59 dankogai Exp $
#
use 5.008001;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Regexp::Optimizer',
    AUTHOR           => q{Dan Kogai <dankogai+cpan@gmail.com>},
    VERSION_FROM     => 'lib/Regexp/Optimizer.pm',
    ABSTRACT_FROM    => 'lib/Regexp/Optimizer.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Regexp::Assemble' =>  0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Regexp-Optimizer-*' },
);
