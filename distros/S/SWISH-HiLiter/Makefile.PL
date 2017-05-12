use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.008003;

# API change warning
print STDERR<<"EOF";

##
## WARNING: The SWISH::HiLiter API has changed significantly
## as of version 0.05. Please read the Changes file and review
## the SWISH::HiLiter documentation. If you use SWISH::HiLiter in
## existing code, **you will need to change your code**.
##
## Press return to continue (or wait 60 seconds)
EOF

unless ( $ENV{'AUTOMATED_TESTING'} ) {
    my %old;

    $old{'ALRM'} = $SIG{'ALRM'} || 'DEFAULT';

    eval {

        # Localize so I only have to restore in my catch block
        local $SIG{'ALRM'} = sub { die 'alarm' };
        alarm(60);
        my $res = <STDIN>;
        alarm(0);
    };

    if ( $@ =~ /alarm/ ) {
        $SIG{'ALRM'} = $old{'ALRM'};
    }
}

my $MM_Version = $ExtUtils::MakeMaker::VERSION;

if ( $MM_Version =~ /_/ )    # dev version
{
    $MM_Version = eval $MM_Version;
    die $@ if ($@);
}

WriteMakefile(
    NAME          => 'SWISH::HiLiter',
    VERSION_FROM  => 'lib/SWISH/HiLiter.pm',
    AUTHOR        => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM  => 'lib/SWISH/HiLiter.pm',
    ABSTRACT_FROM => 'lib/SWISH/HiLiter.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Search::Tools' => 0.26,    # requires Search::Tools
        'Test::More'    => 0,       # Search::Tools req too
        'File::Slurp'   => 0,       # Search::Tools req too
        'Data::Dump'    => 0,       # Search::Tools req too
        'Rose::Object'  => 0,       # Search::Tools req too

    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'SWISH-HiLiter-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44
        ? ()
        : ( META_MERGE => {
                resources => {
                    license  => 'http://dev.perl.org/licenses/',
                    homepage => 'http://perl.peknet.com/wiki/SWISHHiLiter',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-HiLiter',
                    repository => 'http://svn.peknet.com/perl/SWISH-HiLiter',
                },
            }
        )
    ),

);
