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
    NAME          => 'SWISH::Prog::Xapian',
    AUTHOR        => 'Peter Karman <karman at cpan dot org>',
    VERSION_FROM  => 'lib/SWISH/Prog/Xapian.pm',
    ABSTRACT_FROM => 'lib/SWISH/Prog/Xapian.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'                  => 0,
        'Search::Xapian'              => 0,
        'Sort::SQL'                   => 0,
        'Path::Class::File::Lockable' => 0,
        'SWISH::Prog'                 => 0.54,
        'SWISH::3'                    => 1.000001,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'SWISH-Prog-Xapian-* t/index.swish' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        :

            (
            META_MERGE => {
                resources => {
                    license  => 'http://dev.perl.org/licenses/',
                    homepage => 'http://dev.swish-e.org/wiki/perl',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog-Xapian',
                    repository =>
                        'http://svn.swish-e.org/perl/SWISH-Prog-Xapian/',
                },
            }
            )
    ),
);
