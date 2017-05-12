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
    NAME          => 'SVN::Class',
    AUTHOR        => 'Peter Karman <perl@peknet.com>',
    VERSION_FROM  => 'lib/SVN/Class.pm',
    ABSTRACT_FROM => 'lib/SVN/Class.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'              => 0,
        'Data::Dump'              => 0,
        'IPC::Cmd'                => '0.40',
        'IPC::Run'                => 0,        # Win32 needs for sure
        'Path::Class'             => 0,
        'Path::Class::File::Stat' => 0,
        'Rose::Object'            => 0,
        'Rose::URI'               => 0,
        'File::Temp'              => 0,        # tests only
        'Text::ParseWords'        => 0,        # for IPC::Run
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'SVN-Class-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44
        ? ()
        : ( META_MERGE => {
                resources => {
                    license  => 'http://dev.perl.org/licenses/',
                    homepage => 'https://github.com/karpet/svn-class-perl',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=SVN-Class',
                    repository => 'https://github.com/karpet/svn-class-perl',
                },
            }
        )
    ),
);
