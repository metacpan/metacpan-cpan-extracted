use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';
warn "Optional ExtUtils::MakeMaker::Coverage not available\n" if $@;

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'TAP::Formatter::TextMate',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/TAP/Formatter/TextMate.pm',
    ABSTRACT_FROM => 'lib/TAP/Formatter/TextMate.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'             => 0,
        'Test::Harness'          => '2.99',
        'Test::More::Diagnostic' => 0,
        'HTML::Tiny'             => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'TAP-Formatter-TextMate-*' },
);
