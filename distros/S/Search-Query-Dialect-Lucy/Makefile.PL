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
    NAME          => 'Search::Query::Dialect::Lucy',
    AUTHOR        => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM  => 'lib/Search/Query/Dialect/Lucy.pm',
    ABSTRACT_FROM => 'lib/Search/Query/Dialect/Lucy.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'                   => 0,
        'Search::Query'                => '0.300',
        'Moo'                          => 0,
        'Lucy'                         => '0.001000',
        'LucyX::Search::WildcardQuery' => 0.06,
        'LucyX::Search::NullTermQuery' => 0.006,
        'namespace::autoclean'         => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Search-Query-Dialect-Lucy-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        : ( META_MERGE => {
                resources => {
                    license => 'http://dev.perl.org/licenses/',
                    homepage =>
                        'https://github.com/karpet/search-query-dialect-lucy-perl',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Query-Dialect-Lucy',
                    repository =>
                        'https://github.com/karpet/search-query-dialect-lucy-perl',
                },
            }
        )
    ),

);
