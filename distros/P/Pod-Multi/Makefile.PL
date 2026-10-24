use ExtUtils::MakeMaker;
use strict;
use warnings;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

my %WriteMakefileArgs = (
    NAME                => 'Pod::Multi',
    VERSION_FROM        => 'lib/Pod/Multi.pm',
    AUTHOR              => 'James E Keenan (jkeenan@pobox.com)',
    ABSTRACT            => 'pod2man, pod2text, pod2html simultaneously',
    EXE_FILES           => [ 'scripts/pod2multi' ],
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    MIN_PERL_VERSION    => '5.8.0',
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM           => {
           'Pod::Text' => 0,
           'Pod::Man' => 0,
           'Pod::Html' => 0,
           'Carp' => 0,
           'File::Basename' => 0,
           'File::Path' => 0,
           'File::Spec' => 0,
           'File::Save::Home' => 0.03,
           'Data::Dumper' => 0,
    },
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
        'Test::Simple' => 0.44,
        'IO::Capture' => 0.05,
    },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage    => 'http://thenceforward.net/perl/modules/Pod-Multi/',
            repository  => {
                url         => 'https://github.com/jkeenan/Pod-Multi.git',
                web         => 'https://github.com/jkeenan/Pod-Multi',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://github.com/jkeenan/Pod-Multi/issues',
            },
        },
    })),
);

WriteMakefile(%WriteMakefileArgs);
