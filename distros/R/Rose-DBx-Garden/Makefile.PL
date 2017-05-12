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
    NAME          => 'Rose::DBx::Garden',
    AUTHOR        => 'Peter Karman <karman@cpan.org>',
    VERSION_FROM  => 'lib/Rose/DBx/Garden.pm',
    ABSTRACT_FROM => 'lib/Rose/DBx/Garden.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'                             => 0,
        'Rose::DBx::TestDB'                      => 0,      # testing only
        'Data::Dump'                             => 0,      # testing only
        'Path::Class'                            => 0,
        'File::Slurp::Tiny'                      => 0,
        'Rose::DB::Object'                       => 0,
        'Rose::HTML::Objects'                    => 0,
        'File::Basename'                         => 0,
        'Rose::HTMLx::Form::Field::Boolean'      => 0.01,
        'Rose::HTMLx::Form::Field::Autocomplete' => 0,
        'Rose::HTMLx::Form::Field::Serial'       => 0,

    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Rose-DBx-Garden-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44
        ? ()
        : ( META_MERGE => {
                resources => {
                    license  => 'http://dev.perl.org/licenses/',
                    homepage => 'https://github.com/karpet/rose-dbx-garden',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-DBx-Garden',
                    repository => 'https://github.com/karpet/rose-dbx-garden',
                },
            }
        )
    ),
);
