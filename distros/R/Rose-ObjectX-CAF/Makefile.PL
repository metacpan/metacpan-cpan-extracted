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
    NAME          => 'Rose::ObjectX::CAF',
    AUTHOR        => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM  => 'lib/Rose/ObjectX/CAF.pm',
    ABSTRACT_FROM => 'lib/Rose/ObjectX/CAF.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'   => 0,
        'Rose::Object' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Rose-ObjectX-CAF-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        :

            (
            META_MERGE => {
                resources => {
                    license  => 'http://dev.perl.org/licenses/',
                    homepage => 'http://perl.peknet.com/wiki/RoseObjectXCAF',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-ObjectX-CAF',
                    repository =>
                        'http://svn.peknet.com/perl/Rose-ObjectX-CAF',
                },
            }
            )
    ),

);
