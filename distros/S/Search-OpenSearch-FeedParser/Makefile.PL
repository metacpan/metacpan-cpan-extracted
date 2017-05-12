use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Search::OpenSearch::FeedParser',
    AUTHOR             => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM       => 'lib/Search/OpenSearch/FeedParser.pm',
    ABSTRACT_FROM      => 'lib/Search/OpenSearch/FeedParser.pm',
    LICENSE            => 'Artistic_2_0',
    PL_FILES           => {},
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    BUILD_REQUIRES     => { 'Test::More' => 0, },
    PREREQ_PM          => {
        'XML::Feed'          => 0,
        'XML::Simple'        => 0,
        'Search::Tools'      => '1.000',
        'Data::Transformer'  => 0,
        'Test::More'         => 0,
        'Data::Dump'         => 0,
        'Moo'                => 0,
        'Type::Tiny'         => 0,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Search-OpenSearch-FeedParser-*' },
);
