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
    NAME          => 'Search::OpenSearch::Engine::KSx',
    AUTHOR        => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM  => 'lib/Search/OpenSearch/Engine/KSx.pm',
    ABSTRACT_FROM => 'lib/Search/OpenSearch/Engine/KSx.pm',
    (   $MM_Version >= 6.3002 ? ( 'LICENSE' => 'perl' )
        : ()
    ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'         => 0,
        'Search::OpenSearch' => 0.13,
        'SWISH::Prog::KSx'   => 0.17,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Search-OpenSearch-Engine-KSx-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        : ( META_MERGE => {
                resources => {
                    license  => 'http://dev.perl.org/licenses/',
                    homepage => 'http://perl.peknet.com/',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch-Engine-KSx',
                    repository =>
                        'http://svn.peknet.com/perl/Search-OpenSearch-Engine-KSx/',
                },
            }
        )
    ),
);
