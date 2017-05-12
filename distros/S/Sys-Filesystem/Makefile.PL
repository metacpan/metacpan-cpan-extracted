# vim:ts=4:sw=4:tw=78
# $Id$

use 5.008001;

use strict;
use vars qw($build);
use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );

use ExtUtils::MakeMaker;

$@ = undef;
my @fs;
$^O eq 'MSWin32' or eval {
    require Sys::Filesystem;
    unless ( Sys::Filesystem->supported )
    {
        printf( STDERR "Can't be used ($@) - OS not supported or bad maintained?" );
        exit(0);
    }
};

my %RUN_DEPS = (
    'Carp'              => 0,
    'Cwd'               => 0,
    'File::Spec'        => 0,
    'FindBin'           => 0,
    'IO'                => 0,
    'IPC::Cmd'          => '0.80',
    'Module::Pluggable' => '4.8',
    'Params::Util'      => '1.00',
    (
        $^O eq 'MSWin32'
        ? (
            'Win32::DriveInfo' => 0,
          )
        : ()
    ),
);
my %CONFIGURE_DEPS = (
    'ExtUtils::MakeMaker' => 0,
    %RUN_DEPS
);
my %BUILD_DEPS = ();

my %TEST_DEPS = (
    'Test::More' => 0.90,
);

WriteMakefile1(
    MIN_PERL_VERSION => '5.008001',
    META_ADD         => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://metacpan.org/release/Sys-Filesystem',
            repository => {
                url  => 'git@github.com:rehsack/Sys-Filesystem.git',
                web  => 'https://github.com/rehsack/Sys-Filesystem',
                type => 'git',
            },
            bugtracker => {
                web    => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Sys-Filesystem',
                mailto => 'fsys-filesystem@rt.cpan.org',
            },
        },
        prereqs => {
            develop => {
                requires => {
                    'Test::CPAN::Changes'                 => 0,
                    'Test::CheckManifest'                 => 0,
                    'Test::Pod'                           => 0,
                    'Test::Pod::Coverage'                 => 0,
                    'Test::Pod::Spelling::CommonMistakes' => 0,
                },
            },
            configure => {
                requires => {%CONFIGURE_DEPS},
            },
            build   => { requires => {%BUILD_DEPS} },
            test    => { requires => {%TEST_DEPS} },
            runtime => {
                recommends => {
                    'perl' => '5.018001',
                },
                requires => { %RUN_DEPS, },
            },
        },
    },
    NAME           => 'Sys::Filesystem',
    VERSION_FROM   => 'lib/Sys/Filesystem.pm',
    ABSTRACT_FROM  => 'lib/Sys/Filesystem.pm',
    LICENSE        => 'Apache',
    AUTHOR         => [ q{Nicola Worthington <nicolaw@cpan.org>}, q{Jens Rehsack <rehsack@cpan.org>} ],
    PREREQ_PM      => \%RUN_DEPS,
    BUILD_REQUIRES => \%BUILD_DEPS,
    TEST_REQUIRES  => \%TEST_DEPS,
    test           => { TESTS => 't/*.t xt/*.t' },
);

sub WriteMakefile1
{    # originally written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params       = @_;
    my $eumm_version = $ExtUtils::MakeMaker::VERSION;
    $eumm_version = eval $eumm_version;
    die "EXTRA_META is deprecated" if ( exists( $params{EXTRA_META} ) );
    die "License not specified"    if ( !exists( $params{LICENSE} ) );
    if ( $params{TEST_REQUIRES} and ( $eumm_version < 6.6303 ) )
    {
        if ( $params{BUILD_REQUIRES} )
        {
            $params{BUILD_REQUIRES} = { %{ $params{BUILD_REQUIRES} }, %{ $params{TEST_REQUIRES} } };
        }
        else
        {
            $params{BUILD_REQUIRES} = delete $params{TEST_REQUIRES};
        }
    }
    if ( $params{BUILD_REQUIRES} and ( $eumm_version < 6.5503 ) )
    {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM} = { %{ $params{PREREQ_PM} || {} }, %{ $params{BUILD_REQUIRES} } };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES}    if ( $eumm_version < 6.52 );
    delete $params{MIN_PERL_VERSION}      if ( $eumm_version < 6.48 );
    delete $params{META_MERGE}            if ( $eumm_version < 6.46 );
    delete $params{META_ADD}{prereqs}     if ( $eumm_version < 6.58 );
    delete $params{META_ADD}{'meta-spec'} if ( $eumm_version < 6.58 );
    delete $params{META_ADD}              if ( $eumm_version < 6.46 );
    delete $params{LICENSE}               if ( $eumm_version < 6.31 );
    delete $params{AUTHOR}                if ( $] < 5.005 );
    delete $params{ABSTRACT_FROM}         if ( $] < 5.005 );
    delete $params{BINARY_LOCATION}       if ( $] < 5.005 );

    # more or less taken from Moose' Makefile.PL
    if ( $params{CONFLICTS} )
    {
        my $ok = CheckConflicts(%params);
        exit(0) if ( $params{PREREQ_FATAL} and not $ok );
        my $cpan_smoker = grep { $_ =~ m/(?:CR_SMOKER|CPAN_REPORTER|AUTOMATED_TESTING)/ } keys %ENV;
        unless ( $cpan_smoker || $ENV{PERL_MM_USE_DEFAULT} )
        {
            sleep 4 unless ($ok);
        }
        delete $params{CONFLICTS};
    }

    WriteMakefile(%params);
}
