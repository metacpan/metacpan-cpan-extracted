use ExtUtils::MakeMaker;
use strict;

WriteMakefile1(
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            repository => 'http://github.com/dams/params-check-faster',
        },
    },
    #BUILD_REQUIRES => {
    #},

    NAME            => 'Params::Check::Faster',
    VERSION_FROM    => 'lib/Params/Check/Faster.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => { 
                        'Test::More'                => 0, 
                        'Locale::Maketext::Simple'  => 0,    
                    },
    INSTALLDIRS     => ( $] >= 5.009005 && $] < 5.012 ? 'perl' : 'site' ),
    AUTHOR          => 'Damien "dams" Krotkine <dams[at]cpan.org>',
    ABSTRACT        => 'Faster implementation of Params::Check, a templated based param validation'
);


sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;

    WriteMakefile(%params);
}

