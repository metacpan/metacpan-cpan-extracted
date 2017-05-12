use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Search::OpenSearch::Engine::SWISH',
    AUTHOR              => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM        => 'lib/Search/OpenSearch/Engine/SWISH.pm',
    ABSTRACT_FROM       => 'lib/Search/OpenSearch/Engine/SWISH.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Search::OpenSearch' => 0,
        'SWISH::Prog'        => 0.37,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Search-OpenSearch-Engine-SWISH-*' },
);
