use ExtUtils::MakeMaker;

my %config = (
    NAME          => 'Siebel::AssertOS',
    VERSION_FROM  => 'lib/Siebel/AssertOS.pm',    # finds $VERSION
    PREREQ_PM     => {},
    TEST_REQUIRES => {
        'Test::More'          => 0,
        'Test::Pod'           => 1.22,
        'Test::Pod::Coverage' => 1.08
    },
    META_MERGE => {
        resources => {
            license  => 'http://www.gnu.org/licenses/gpl.txt',
            homepage => 'https://github.com/glasswalk3r/siebel-gnu-tools',
            bugtracker =>
              'https://github.com/glasswalk3r/siebel-gnu-tools/issues',
            repository => 'https://github.com/glasswalk3r/siebel-gnu-tools'
        },
    },
    dist => { SUFFIX => '.gz', COMPRESS => 'gzip --best' },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Siebel/AssertOS.pm',    # retrieve abstract from module
            AUTHOR => 'Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>'
          )
        : ()
    ),
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'gpl', ) : () )
);

my_WriteMakefile(%config);

sub my_WriteMakefile
{ #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 0.23. Added by eumm-upgrade.

    my %params       = @_;
    my $eumm_version = $ExtUtils::MakeMaker::VERSION;
    $eumm_version = eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};

    if (    $params{AUTHOR}
        and ref( $params{AUTHOR} ) eq 'ARRAY'
        and $eumm_version < 6.5705 )
    {
        $params{META_ADD}->{author} = $params{AUTHOR};
        $params{AUTHOR} = join( ', ', @{ $params{AUTHOR} } );
    }

    if ( $params{TEST_REQUIRES} and $eumm_version < 6.64 ) {
        $params{BUILD_REQUIRES} =
          { %{ $params{BUILD_REQUIRES} || {} }, %{ $params{TEST_REQUIRES} } };
        delete $params{TEST_REQUIRES};
    }

    if ( $params{BUILD_REQUIRES} and $eumm_version < 6.5503 ) {

        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM} =
          { %{ $params{PREREQ_PM} || {} }, %{ $params{BUILD_REQUIRES} } };
        delete $params{BUILD_REQUIRES};
    }

    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION}   if $eumm_version < 6.48;

    if ( $eumm_version < 6.46 ) {

        delete $params{META_MERGE};
        delete $params{META_ADD};

    }
    delete $params{LICENSE} if $eumm_version < 6.31;

    WriteMakefile(%params);
}

