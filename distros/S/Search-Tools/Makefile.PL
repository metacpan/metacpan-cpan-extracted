use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.008003;

my $MM_Version = $ExtUtils::MakeMaker::VERSION;

if ( $MM_Version =~ /_/ )    # dev version
{
    $MM_Version = eval $MM_Version;
    die $@ if ($@);
}

WriteMakefile(
    NAME          => 'Search::Tools',
    VERSION_FROM  => 'lib/Search/Tools.pm',
    AUTHOR        => q{Peter Karman <karman@cpan.org>},
    ABSTRACT_FROM => 'lib/Search/Tools.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Moo'                  => 0,
        'namespace::autoclean' => 0,
        'Search::Query'        => '0.300',
        'Encode'               => '0',
        'Class::XSAccessor'    => '0.14',
        'Data::Dump'           => 0,
        'Test::More'           => 0.94,
        'Encoding::FixLatin'   => 0,
        'File::Basename'       => 0,
        'Scalar::Util'         => 0,

        #'Text::Aspell'          => '0.06',  # optional

    },
    H => [qw( search-tools.c search-tools.h )],

    #CCFLAGS => '-Wall -pg', # gcc opt only
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Search-Tools-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        :

            (
            META_MERGE => {
                resources => {
                    license  => 'http://dev.perl.org/licenses/',
                    homepage => 'https://github.com/karpet/search-tools-perl',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Tools',
                    repository =>
                        'https://github.com/karpet/search-tools-perl',
                },
            }
            )
    ),

);
