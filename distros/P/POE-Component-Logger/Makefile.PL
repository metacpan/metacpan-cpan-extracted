use 5.006;
use strict;

use ExtUtils::MakeMaker;
WriteMakefile1(
    MIN_PERL_VERSION => '5.008',

    NAME => 'POE::Component::Logger',
    VERSION_FROM => 'lib/POE/Component/Logger.pm',
    ABSTRACT_FROM => 'lib/POE/Component/Logger.pm',
    AUTHOR => 'Matt Sergeant <matt@sergeant.org>',
    LICENSE => 'perl',
    BUILD_REQUIRES => {
        'Test::More' => '0',
        'Test::Builder' => '0',
        'Test::NoWarnings' => '0',
    },
    PREREQ_PM => {
        # core
        'File::Spec' => '0',
	'Carp' => '0',
	'base' => '0',
        # CPAN
        'Log::Dispatch' => '2.26',
        'Log::Dispatch::Config' => '1.03',
        'POE' => '1.293',
    },
    META_MERGE => {
        resources => {
            repository => 'http://github.com/dolmen/POE-Component-Logger',
            homepage => 'http://github.com/dolmen/POE-Component-Logger',
        },
    },
);

# vim: set et sw=4 sts=4 :

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

