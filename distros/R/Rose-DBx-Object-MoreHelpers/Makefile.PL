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
    NAME          => 'Rose::DBx::Object::MoreHelpers',
    AUTHOR        => 'Peter Karman <karman@cpan.org>',
    VERSION_FROM  => 'lib/Rose/DBx/Object/MoreHelpers.pm',
    ABSTRACT_FROM => 'lib/Rose/DBx/Object/MoreHelpers.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'        => 0,
        'Rose::DB::Object'  => 0.770,
        'Rose::DBx::TestDB' => 0,
        'Scalar::Util'      => 0,
        'Math::BigInt'      => 0,
        'Data::Dump'        => 0,

    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Rose-DBx-Object-MoreHelpers-*' },

    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        :

            (
            META_MERGE => {
                resources => {
                    license => 'http://dev.perl.org/licenses/',
                    homepage =>
                        'https://github.com/karpet/rose-dbx-object-morehelpers',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-DBx-Object-MoreHelpers',
                    repository =>
                        'https://github.com/karpet/rose-dbx-object-morehelpers',
                },
            }
            )
    ),
);
