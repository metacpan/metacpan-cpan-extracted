use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::CardDAVTalk',
    AUTHOR           => q{Bron Gondwana <brong@cpan.org>},
    VERSION_FROM     => 'lib/Net/CardDAVTalk.pm',
    ABSTRACT_FROM    => 'lib/Net/CardDAVTalk.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'List::Pairwise'    => '1.00',
        'List::MoreUtils'   => '0.01',
        'XML::Spice'        => '0.04',
        'Net::DAVTalk'      => '0.08',
        'Text::VCardFast'   => '0.07',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-CardDAVTalk-*' },
);
