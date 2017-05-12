use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::CalDAVTalk',
    AUTHOR           => q{Bron Gondwana <brong@cpan.org>},
    VERSION_FROM     => 'lib/Net/CalDAVTalk.pm',
    ABSTRACT_FROM    => 'lib/Net/CalDAVTalk.pm',
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
        'Net::DAVTalk' => '0.02',
        'DateTime::TimeZone' => 0,
        'Data::ICal::TimeZone' => '1.23',
        'DateTime::Format::ISO8601' => '0.08',
        'DateTime::Format::ICal' => '0.09',
        'Text::LevenshteinXS' => '0.03',
        'Text::VCardFast' => '0.06',
        'JSON' => 0,
        'JSON::XS' => 0,
        'MIME::Types' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-CalDAVTalk-*' },
);
