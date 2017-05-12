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
    NAME          => 'Search::OpenSearch::Engine::Xapian',
    AUTHOR        => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM  => 'lib/Search/OpenSearch/Engine/Xapian.pm',
    ABSTRACT_FROM => 'lib/Search/OpenSearch/Engine/Xapian.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'          => 0,
        'Search::OpenSearch'  => 0.15,
        'SWISH::Prog::Xapian' => 0.08,
        'SWISH::Prog'         => 0.54,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Search-OpenSearch-Engine-Xapian-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        : ( META_MERGE => {
                resources => {
                    license => 'http://dev.perl.org/licenses/',
                    homepage =>
                        'https://github.com/karpet/search-opensearch-engine-xapian-perl',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch-Engine-Xapian',
                    repository =>
                        'git://github.com/karpet/search-opensearch-engine-xapian-perl.git',
                },
            }
        )
    ),
);
