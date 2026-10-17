use ExtUtils::MakeMaker;
use strict;
use warnings;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

my %WriteMakefileArgs = (
    NAME         => 'Parse::File::Metadata',
    VERSION_FROM => 'lib/Parse/File/Metadata.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@pobox.com)',
    ABSTRACT     => 'For plain-text files that contain metadata (in key-value pairs) and data records, parse metadata first before proceeding',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    MIN_PERL_VERSION    => '5.8.0',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM    => {
        'Carp' => 0,
        'File::Spec' => 0,
        'Scalar::Util' => 0,
    },
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
        "Test::Simple" => 0.44,
    },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage    => 'http://thenceforward.net/perl/modules/Parse-File-Metadata/',
            repository  => {
                url         => 'https://github.com/jkeenan/Parse-File-Metadata.git',
                web         => 'https://github.com/jkeenan/Parse-File-Metadata',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://github.com/jkeenan/Parse-File-Metadata/issues',
            },
        },
    })),
);

WriteMakefile(%WriteMakefileArgs);
