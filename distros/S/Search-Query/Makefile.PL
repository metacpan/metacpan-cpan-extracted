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
    NAME          => 'Search::Query',
    AUTHOR        => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM  => 'lib/Search/Query.pm',
    ABSTRACT_FROM => 'lib/Search/Query.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    EXE_FILES => [ q[bin/sqd], ],
    PREREQ_PM => {
        'Test::More'           => 0,
        'Data::Dump'           => 0,
        'Moo'                  => 0,
        'Type::Tiny'           => 0,
        'namespace::autoclean' => 0.28,
        'Data::Transformer'    => 0,
        'Scalar::Util'         => 0,
        'Module::Pluggable'    => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Search-Query-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        : ( META_MERGE => {
                resources => {
                    license  => 'http://dev.perl.org/licenses/',
                    homepage => 'https://github.com/karpet/search-query-perl',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Query',
                    repository =>
                        'https://github.com/karpet/search-query-perl',
                },
            }
        )
    ),
);
