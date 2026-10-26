use strict;
use warnings;
use ExtUtils::MakeMaker;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

my %WriteMakefileArgs = (
    NAME         => 'Set::Integer::Gapfillers',
    VERSION_FROM => 'lib/Set/Integer/Gapfillers.pm',
    AUTHOR       => 'James E Keenan (jkeenan@pobox.com)',
    ABSTRACT     => 'Fill in the gaps between integer ranges',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM    => { },
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
                     'Test::Simple' => 0.44,
    },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/Set-Integer-Gapfillers/',
            repository => {
                url => 'https://github.com/jkeenan/Set-Integer-Gapfillers.git',
                web => 'https://github.com/jkeenan/Set-Integer-Gapfillers',
                type => 'git',
            },
            bugtracker => {
                web         => 'https://github.com/jkeenan/Set-Integer-Gapfillers/issues',
            },
        },
    })),
);

WriteMakefile(%WriteMakefileArgs);
