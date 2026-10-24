use ExtUtils::MakeMaker;
use strict;
use warnings;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

my %WriteMakefileArgs = (
    NAME         => 'String::PerlIdentifier',
    VERSION_FROM => 'lib/String/PerlIdentifier.pm',
    AUTHOR       => 'James E Keenan (jkeenan@pobox.com)',
    ABSTRACT     => 'Generate a random name for a Perl variable',
    INSTALLDIRS  => ($] < 5.011 ? 'perl' : 'site'),
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM    => {
                    },
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
        "Test::Simple" => 0.44,
    },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage    => 'http://thenceforward.net/perl/modules/String-PerlIdentifier/',
            repository  => {
                url         => 'https://github.com/jkeenan/String-PerlIdentifier.git',
                web         => 'https://github.com/jkeenan/String-PerlIdentifier',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://github.com/jkeenan/String-PerlIdentifier/issues',
            },
        },
    })),
);

WriteMakefile(%WriteMakefileArgs);
