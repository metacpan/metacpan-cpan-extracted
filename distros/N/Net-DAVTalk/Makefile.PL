use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::DAVTalk',
    AUTHOR           => q{Bron Gondwana <brong@cpan.org>},
    VERSION_FROM     => 'lib/Net/DAVTalk.pm',
    ABSTRACT_FROM    => 'lib/Net/DAVTalk.pm',
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
        'HTTP::Tiny'                => '0.016',
        'Tie::DataUUID'             => '1.02',
        'URI'                       => '1.60',
        'XML::Fast'                 => '0.11',
        'XML::Spice'                => '0.03',
        'JSON'                      => 0,
        'JSON::XS'                  => 0,
        'DateTime::Format::ISO8601' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-DAVTalk-*' },
);
