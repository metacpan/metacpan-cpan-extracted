use strict;
use warnings;
use ExtUtils::MakeMaker;

my $MM_Version = $ExtUtils::MakeMaker::VERSION;

if ( $MM_Version =~ /_/ )    # dev version
{
    $MM_Version = eval $MM_Version;
    die $@ if ($@);
}

WriteMakefile(
    NAME          => 'Search::OpenSearch::Engine::Lucy',
    AUTHOR        => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM  => 'lib/Search/OpenSearch/Engine/Lucy.pm',
    ABSTRACT_FROM => 'lib/Search/OpenSearch/Engine/Lucy.pm',
    (   $MM_Version >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : ()
    ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'                   => 0,
        'Moose'                        => 0,
        'Type::Tiny'                   => 0,
        'Search::OpenSearch'           => '0.400',
        'Search::Tools'                => '1.000',
        'Search::Query::Dialect::Lucy' => '0.200',
        'Dezi::App'                    => '0.004',
        'Class::Load'                  => 0,
        'JSON'                         => 2.00,
        'Path::Class' => 0,    # required by Dezi::App but be explicit
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'test.index Search-OpenSearch-Engine-Lucy-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44
        ? ()
        : ( META_MERGE => {
                resources => {
                    license => 'http://dev.perl.org/licenses/',
                    homepage =>
                        'https://github.com/karpet/search-opensearch-engine-lucy-perl',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch-Engine-Lucy',
                    repository =>
                        'git://github.com/karpet/search-opensearch-engine-lucy-perl.git',
                },
            }
        )
    ),
);
