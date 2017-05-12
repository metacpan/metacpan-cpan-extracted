#!perl

use 5.010000;

use strict;
use warnings;
use ExtUtils::MakeMaker;

# most of this perhaps all stolen from mauke
sub merge_key_into {
    my ( $href, $target, $source ) = @_;
    %{ $href->{$target} } = ( %{ $href->{$target} }, %{ delete $href->{$source} } );
}

my %params = (
    NAME          => 'Music::AtonalUtil',
    AUTHOR        => 'Jeremy Mates <jmates@cpan.org>',
    ABSTRACT_FROM => 'lib/Music/AtonalUtil.pm',
    VERSION_FROM  => 'lib/Music/AtonalUtil.pm',

    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => 5.10.0,

    CONFIGURE_REQUIRES => {
        'strict'              => 0,
        'ExtUtils::MakeMaker' => '6.48',
    },
    BUILD_REQUIRES => {},
    TEST_REQUIRES  => {
        'Test::Most' => 0,
        # Mandate the POD tests, contrary to the dagolden no-pod-tests fad. I rank
        # documentation on par with the code, not something one can maybe remember
        # to maybe run the release testing for.
        'Pod::Coverage'       => 0.18,
        'Test::Pod::Coverage' => 1.08,
        'Test::Pod'           => 1.22,
        'lib'                 => 0,
    },
    # List everything due to certain linux vendors chopping up core perl, or
    # otherwise to detect and fail if being installed to a broken perl install.
    PREREQ_PM => {
        'Algorithm::Combinatorics' => 0,
        Carp                       => 0,
        'List::Util'               => 0,
        'Scalar::Util'             => 0,
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        'resources' => {
            repository => {
                url  => 'git://github.com/thrig/Music-AtonalUtil.git',
                web  => 'https://github.com/thrig/Music-AtonalUtil',
                type => 'git',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Music-AtonalUtil-*' },
);

(   my $mm_version = ExtUtils::MakeMaker->VERSION(
        $params{CONFIGURE_REQUIRES}{'ExtUtils::MakeMaker'}
    )
) =~ tr/_//d;

if ( $mm_version < 6.67_04 ) {
    *ExtUtils::MM_Any::_add_requirements_to_meta_v1_4 =
      \&ExtUtils::MM_Any::_add_requirements_to_meta_v2;
}

if ( $mm_version < 6.63_03 ) {
    merge_key_into \%params, 'BUILD_REQUIRES', 'TEST_REQUIRES';
}

if ( $mm_version < 6.55_01 ) {
    merge_key_into \%params, 'CONFIGURE_REQUIRES', 'BUILD_REQUIRES';
}

if ( $mm_version < 6.51_03 ) {
    merge_key_into \%params, 'PREREQ_PM', 'CONFIGURE_REQUIRES';
}

WriteMakefile( ( MM->can('signature_target') ? ( SIGN => 1 ) : () ), %params );
