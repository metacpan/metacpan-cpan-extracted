use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Storable::Improved',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT_FROM       => 'lib/Storable/Improved.pm',
    VERSION_FROM        => 'lib/Storable/Improved.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'parent'        => 0,
        'strict'        => 0,
        'warnings'      => 0,
        'Scalar::Util'  => '1.50',
        'Storable'      => '3.25',
    },
    TEST_REQUIRES =>
    {
        'Test::More'    => 0,
        'IO::File'      => 0,
        'HTTP::XSHeaders' => 0,
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.26.1',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Storable-Improved-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Storable-Improved.git',
                web         => 'https://gitlab.com/jackdeguest/Storable-Improved',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Storable-Improved/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
