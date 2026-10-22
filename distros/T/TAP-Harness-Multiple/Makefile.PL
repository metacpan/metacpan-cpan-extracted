use strict;
use warnings;
use ExtUtils::MakeMaker;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

my %WriteMakefileArgs = (
    NAME         => 'TAP::Harness::Multiple',
    VERSION      => '0.08',
    AUTHOR       => 'James E Keenan (jkeenan@pobox.com)',
    ABSTRACT     => 'Run and archive multiple test harnesses in a single harness',
    INSTALLDIRS  => ($] < 5.011 ? 'perl' : 'site'),
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM    => {
                     'TAP::Harness::Archive' => 0.14,
                     'Test::Harness' => 3.23,
                     'File::Path' => 2.07,
                    },
    LICENSE     => 'perl',
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
        "Test::Simple" => 0.44,
        'IO::CaptureOutput' => 0, # for testing only
    },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage    => 'http://thenceforward.net/perl/modules/TAP-Harness-Multiple/',
            repository  => {
                url         => 'https://github.com/jkeenan/TAP-Harness-Multiple.git',
                web         => 'https://github.com/jkeenan/TAP-Harness-Multiple',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://github.com/jkeenan/TAP-Harness-Multiple/issues',
            },
        },
    })),
);

WriteMakefile(%WriteMakefileArgs);
